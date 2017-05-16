// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:path/path.dart' as p;

import 'package:convertX/src/dicom_no_tag/compare_bytes.dart';
import 'package:convertX/src/dicom_no_tag/byte_dataset.dart';
import 'package:convertX/src/dicom_no_tag/dcm_reader.dart';

import 'package:convertX/timer.dart';
import 'package:convertX/src/dicom_no_tag/utils.dart';
import 'utils.dart';

String path0 = 'C:/odw/test_data/IM-0001-0001.dcm';
String path1 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255'
    '.393386351.1568457295.17895.5.dcm';
String path2 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm';
String path3 =
    'C:/odw/test_data/sfd/CT/Patient_4_3_phase_abd/1_DICOM_Original/IM000002.dcm';
String path4 =
    'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264.20120723195848/1.2'
    '.392.200036.9125.3.3315591109239.64688154694.35921044/1.2.392.200036.9125.9.0.252688780.254812416.1536946029.dcm';
String path5 =
    'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264.20120723195848/2.16.840.1.114255.1870665029.949635505.39523.169/2.16.840.1.114255.1870665029.949635505.10220.175.dcm';
String path6 = "C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16"
    ".840.1.114255.390617858.1794098916.62037.38690.dcm";

List<String> paths = <String>[path0, path1, path2, path3, path4, path5];

final Logger log =
    new Logger("convert/bin/read_write_files.dart", watermark: Severity.config);

String testData = "C:/odw/test_data";
String sfd = "C:/odw/test_data/sfd";
String test6688 = "C:/odw/test_data/6688";
String mWeb = "C:/odw/test_data/mweb";
String mrStudy = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";

void main() {
  // File file = new File(path0);
  // readWriteFileFast(file, reps: 10, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readWriteFiles(paths, fmiOnly: false);
  readWriteDirectory(sfd, fmiOnly: false);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

final String _tempDir = Directory.systemTemp.path;
final Stopwatch _watch = new Stopwatch();

const int kMB = 1024 * 1024;

String mbps(int lib, int us) => (lib / us).toStringAsFixed(1);
String fmt(double v) => v.toStringAsFixed(1).padLeft(7, ' ');
String inMS(Duration v) =>
    (v.inMicroseconds / 1000).toStringAsFixed(1).padLeft(7, ' ');

void readWriteDirectory(String path,
    {bool fmiOnly = false,
    int printEvery = 100,
    bool throwOnError = false,
    String fileExt = '.dcm',
    int shortFileThreshold = 1024}) {
  Directory dir = new Directory(path);
  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fList.retainWhere((fse) => fse is File);
  int fileCount = fList.length;
  log.info('$fileCount files');

  //TODO: make this work
  File errFile = new File('bin/no_tag/errors.log');
  errFile.openWrite(mode: FileMode.WRITE_ONLY_APPEND);
  var startTime = new DateTime.now();

  log.info('Reading $path ...\n'
      '    with $fileCount files\n'
      '    at $startTime');

  Timer timer = new Timer();
  int count = -1;
  int success = 0;
  int failure = 0;
  List<String> badTS = <String>[];
  List<String> badExt = <String>[];
  List<String> errors = <String>[];
  for (File f in fList) {
    count++;
    if (count % printEvery == 0) {
      var split = timer.split;
      var now = timer.elapsed;
      var n = '${count.toString().padLeft(6, " ")}';
      log.info('$n good($success), bad($failure) +${inMS(split)} $now');
    }
    log.debug('$count length(${f.lengthSync() ~/ 1000}KB): $f');
    var path = f.path;
    var fileExt = p.extension(path);
    if (fileExt != "" && fileExt != ".dcm") {
      print('fileExt: "$fileExt"');
      log.error('Non DICOM file??? $path');
      badExt.add('"$path"');
      continue;
    } else {
      log.debug('Reading $path');
      bool v;
      try {
        v = readWriteFileFast(f);
        if (!v) {
          log.error('Error:$f');
          failure++;
        } else {
          success++;
        }
      } on InvalidTransferSyntaxError catch(e) {
        badTS.add('$e: "$path"');
        continue;
      }
      catch(e) {
        errors.add('"$path"');
        log.error(e);
        log.error('  $f');
        v = false;
        failure++;
      }
    }

  }
  timer.stop();
  log.info('Elapsed Time: ${timer.elapsed}');
  print('$badTS');
  print('$badExt');
  print('$errors');
}

bool readWriteFileFast(File inFile, {int reps = 1, bool fmiOnly = false}) {
  Uint8List bytes0 = inFile.readAsBytesSync();
  if (bytes0 == null) return false;
  RootByteDataset rds0 = DcmReader.readBytes(bytes0);
  if (rds0 == null) return false;
  Uint8List bytes1 = writeDataset(rds0);
  if (bytes1 == null) return false;
  return bytesEqual(bytes0, bytes1);
}
