// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:path/path.dart' as p;
import 'package:core/core.dart';

import 'package:convertX/src/dicom_no_tag/compare_bytes.dart';
import 'package:convertX/src/dicom_no_tag/dcm_byte_reader.dart';
import 'package:convertX/timer.dart';
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

String path7 = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';

final Logger log =
    new Logger("convert/bin/read_write_files.dart", watermark: Severity.config);

String testData = "C:/odw/test_data";
String sfd = "C:/odw/test_data/sfd";
String test6688 = "C:/odw/test_data/6688";
String mWeb = "C:/odw/test_data/mweb";
String mrStudy = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";

void main() {
  // readWriteFileFast(new File(path7), reps: 1, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readWriteFiles(paths, fmiOnly: false);
   readWriteDirectory(mrStudy, fmiOnly: true);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

final String _tempDir = Directory.systemTemp.path;
final Stopwatch _watch = new Stopwatch();

const int kMB = 1024 * 1024;

String mbps(int lib, int us) => (lib / us).toStringAsFixed(1);
String fmt(double v) => v.toStringAsFixed(1).padLeft(7, ' ');

List<String> shortFiles = <String>[];
int shortFileMark;

void readWriteDirectory(String path,
    {bool fmiOnly = false,
    int printEvery = 100,
    bool throwOnError = false,
    String fileExt = '.dcm',
    int shortFileThreshold = 1024,
    bool isTimed = false}) {
  shortFileMark = shortFileThreshold;
  Directory dir = new Directory(path);
  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fList.retainWhere((fse) => fse is File);
  int fileCount = fList.length;
  log.config('$fileCount files');

  //TODO: make this work
  File errFile = new File('bin/no_tag/errors.log');
  errFile.openWrite(mode: FileMode.WRITE_ONLY_APPEND);
  var startTime = new DateTime.now();

  log.config('Reading $path ...\n'
      '    with $fileCount files\n'
      '    at $startTime\n'
      ' Count   Good    Bad Seconds        Elapsed');

  Timer timer = new Timer(start: true);
  int count = -1;
  int good = 0;
  int bad = 0;
  List<String> badTS = <String>[];
  List<String> badExt = <String>[];
  List<String> errors = <String>[];

  for (File f in fList) {
    count++;
    if (count % printEvery == 0) currentStats(count, good, bad, timer);
    log.debug('$count length(${f.lengthSync() ~/ 1000}KB): $f');
    var path = f.path.replaceAll('\\', '/');
    var fileExt = p.extension(path);
    if (fileExt != "" && fileExt != ".dcm") {
      log.debug('fileExt: "$fileExt"');
      log.info('Non DICOM file??? $path');
      badExt.add('"$path"');
      continue;
    } else {
      log.debug('Reading $path');
      bool v;
      try {
        v = (isTimed) ? readWriteFileTimed(f) : readWriteFileFast(f);
        if (!v) {
          log.error('Error:$f');
          errors.add('"$path"');
          bad++;
        } else {
          good++;
        }
      } on InvalidTransferSyntaxError catch (e) {
        badTS.add('"${e.ts.asString}": "$path"');
        continue;
      } catch (e) {
        errors.add('"$path"');
        log.error(e);
        log.error('  $f');
        v = false;
        bad++;
        if (throwOnError) rethrow;
      }
    }
  }
  timer.stop();
  currentStats(count, good, bad, timer);

  log.config('Elapsed Time: ${timer.elapsed}');
  log.config('Map<String, String> badTS = '
      '<String, String>{${badTS.join(',\n')}};');
  log.config('List<String> badFileExtension = [${badExt.join(',\n')}];');
  log.config('List<String> errors = [ ${errors.join(',\n')}');
}

String padNumber(int n, [int width = 6, String padChar = " "]) =>
 '${n.toString().padLeft(width, padChar)}';

void currentStats(int count, int good, int bad, Timer timer) {
  var seconds = timer.split.inMicroseconds / 1000;
  var now = timer.elapsed;
  var us = seconds.toStringAsFixed(3).padLeft(6, ' ');
  log.config('${padNumber(count)} ${padNumber(count)} '
  '${padNumber(count)} $us $now');
}

bool readWriteFileFast(File file, {int reps = 1, bool fmiOnly = false}) {
  log.info('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  if (bytes0 == null) return false;
  if (bytes0.length <= shortFileMark) shortFiles.add('"${file.path}"');
  RootByteDataset rds0 = DcmByteReader.readBytes(bytes0, path: file.path);
  if (rds0 == null) return false;
  log.info(rds0);
  Uint8List bytes1 = writeDataset(rds0);
  if (bytes1 == null) return false;
  return bytesEqual(bytes0, bytes1);
}

//TODO: cleanup timing
bool readWriteFileTimed(File file, {int reps = 1, bool fmiOnly = false}) {
  log.info('Reading: $file');
  var timer = new Timer(start: true);

  Uint8List bytes0 = file.readAsBytesSync();
  var readBytes = timer.split;
  if (bytes0 == null) return false;
  if (bytes0.length <= shortFileMark) shortFiles.add('"${file.path}"');

  RootByteDataset rds0 = DcmByteReader.readBytes(bytes0, path: file.path);
  var parse = timer.split;
  if (rds0 == null) return false;


  var bytes1 = writeDataset(rds0);
  var writeDS = timer.split;


  if (bytes1 == null) return false;

  bool areEqual = bytesEqual(bytes0, bytes1);
  Duration compare = timer.split;
  var total = timer.elapsed;
  var out = '''
  ${rds0.info}
    Read bytes: $readBytes
         Parse: $parse
  Read & Parse: ${readBytes + parse}
         Write: $writeDS
       Compare: $compare
         Total: $total
  ''';
  log.config(out);
  return areEqual;
}
