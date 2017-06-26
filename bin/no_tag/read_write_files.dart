// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:convertX/src/dicom_no_tag/compare_bytes.dart';
import 'package:convertX/src/dicom_no_tag/dcm_reader.dart';
import 'package:convertX/src/dicom_no_tag/old/dataset.dart';
import 'package:convertX/timer.dart';
import 'package:dictionary/dictionary.dart';
import 'package:path/path.dart' as p;

import 'read_utils.dart';

final Logger log =
    new Logger("convert/bin/read_write_files.dart", watermark: Severity.info);

String testData = "C:/odw/test_data";
String test6688 = "C:/odw/test_data/6688";
String mWeb = "C:/odw/test_data/mweb";
String mrStudy = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";

String badFile1 = "C:/odw/test_data/mweb/100 MB Studies/Site 3/Case 1 Ped"
    "/1.2.840.113704.1.111.8916.1202763720.15"
    "/1.2.840.113704.1.111.1608.1202763888.37524.dcm ";
void main() {
 // File file = new File(ivrle);
 // readWriteFileTimed(file, reps: 10, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readWriteFiles(paths, fmiOnly: false);
  readWriteDirectory(mrStudy, fmiOnly: false);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}


void readWriteFiles(List<String> paths, {bool fmiOnly = false}) {
  for (String path in paths) readWriteFileTiming(new File(path));
}

final String tempDir = Directory.systemTemp.path;
final Stopwatch watch = new Stopwatch();

const int kMB = 1024 * 1024;

bool readWriteFileFast(File inFile, {int reps = 1, bool fmiOnly = false}) {
  Uint8List bytes0 = inFile.readAsBytesSync();
  RootDataset rds0 = DcmReader.readBytes(bytes0);
  Uint8List bytes1 = writeDataset(rds0);
 // RootDataset rds1 =
  DcmReader.readBytes(bytes1);
  return _bytesEqual(bytes0, bytes1);
}

bool readWriteFileTimed(File inFile, {int reps = 1, bool fmiOnly = false}) {
  /* create a version of fPrint that does this stuff
  String mbps(int lib, int us) => (lib / us).toStringAsFixed(1);
  */
  String fmt(double v) => v.toStringAsFixed(1).padLeft(7, ' ');

  String inMS(Duration v) =>
      (v.inMicroseconds / 1000).toStringAsFixed(1).padLeft(7, ' ');

  log.info('File: ${inFile.path}');
  Timer timer = new Timer();
  Uint8List bytes0 = inFile.readAsBytesSync();
  int lengthIB = bytes0.lengthInBytes;
  Duration rbTime = timer.split;
  log.info('     read: ${inMS(rbTime)} ms');

  for (int i = 0; i < reps; i++) {

    RootDataset rds0 = DcmReader.readBytes(bytes0);
    Duration readDS0 = timer.split;

    Uint8List bytes1 = writeDataset(rds0);
    Duration writeDS0 = timer.split;

  //  RootDataset rds1 =
    DcmReader.readBytes(bytes1);
    Duration readDS1 = timer.split;

    bool hasProblem = _bytesEqual(bytes0, bytes1);
    Duration compare = timer.split;
    Duration total = timer.elapsed;



    log.info('      Loop: $i');
    log.info('    parse0: ${inMS(readDS0)} ms');
    log.info('     write: ${inMS(writeDS0)} ms');
    log.info('    parse1: ${inMS(readDS1)} ms');
    log.info('   compare: ${inMS(compare)} ms');
    log.info('problem(s): $hasProblem');
    log.info('            ${fmt((lengthIB ~/ 1024) / 1000)} MB');
    log.info('            ${inMS(total)} ms');
    log.info('            ${fmt(lengthIB / total.inMicroseconds)} MB/s');
  }
  //TODO: finish
  return true;
}

FileResult readWriteFileTiming(File file,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    bool throwOnError = false,
    bool writeOutputFile = false,
    bool shouldCompareDatasets = true}) {
  var path = file.path;
  var base = p.basename(path);
  var outPath = '$tempDir/$base';
  var outFile = new File(outPath);
  var outFileCreated = false;
  File inFile = new File(path);
  bool hasProblem = false;
  FileResult result;

  try {
    Timer timer = new Timer();

    Duration start = timer.elapsed;
    Uint8List bytes0 = inFile.readAsBytesSync();
    Duration readBD = timer.elapsed;

    if (bytes0 == null) {
      log.error('Could not read "$path"');
      watch.stop();
      return null;
    }

    RootDataset rds0 = DcmReader.readBytes(bytes0);
    Duration readDS0 = timer.elapsed;

    Uint8List bytes1 = writeDataset(rds0, path: path);
    Duration writeDS0 = timer.elapsed;

    RootDataset rds1 = DcmReader.readBytes(bytes1);
    Duration readDS1 = timer.elapsed;

    //TODO: make this work?
    Duration compareDS;
    if (shouldCompareDatasets) {
      bool v = _compareDatasets(rds0, rds1);
      compareDS = timer.elapsed;
      if (!v) {
        log.error('Unequal datasets:/n'
            '  rds0: ${rds0.total}/n'
            '  rds1: ${rds1.total}/n');
        hasProblem = true;
      }
    }

    bool v = _bytesEqual(bytes0, bytes1, throwOnError);
    Duration stop = timer.elapsed;
    if (!v) hasProblem = true;

    var times = new FileTiming(
        file, start, stop, readBD, readDS0, writeDS0, readDS1, compareDS);

    result = new FileResult(file, rds0,
        fmiOnly: fmiOnly,
        targetTS: targetTS,
        times: times,
        hasProblem: hasProblem);

    //TODO: flush if not useful
    /*
    if (writeOutputFile) {
      outFile.writeAsBytesSync(bytes1);
      Duration writeBD = getElapsed();
      outFileCreated = true;

      Uint8List bytes2 = outFile.readAsBytesSync();
      Duration readBD2 = getElapsed();

      RootDataset rds2 = DcmReader.readBytes(bytes1);
      Duration readDS2 = getElapsed();

      if (shouldCompareDatasets) {
        hasProblem = _compareDatasets(rds0, rds1, throwOnError);
        Duration compareDS2 = getElapsed();
      }

      hasProblem = compareBytes(bytes0, bytes1, throwOnError);
      Duration compareBD2 = getElapsed();
    }
    */

  } catch (e) {
    log.error('*** readWriteFile: $e');
    if (throwOnError) rethrow;
    hasProblem = true;
  } finally {
    watch.stop();
    if (outFileCreated) outFile.delete();
  }
  return result;
}

bool _compareDatasets(RootDataset rds0, RootDataset rds1, [bool throwOnError]) {
  bool v = compareDatasets(rds0, rds1, throwOnError);
  if (!v) {
    log.error('Unequal datasets:/n'
        '  rds0: ${rds0.total}/n'
        '  rds1: ${rds1.total}/n');
    return false;
  }
  return true;
}

bool _bytesEqual(Uint8List b0, Uint8List b1, [bool throwOnError]) {
  bool v = bytesEqual(b0, b1, true);
  if (!v) {
    log.error('Unequal datasets:/n'
        '  Bytes0: $b0/n'
        '  Bytes1: $b1/n');
    return false;
  }
  return true;
}

//TODO: make this use streams.
ResultSet readWriteDirectory(String path,
    {bool fmiOnly = false,
    bool throwOnError = true,
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

  var rSet =
  new ResultSet(dir, fList.length, fmiOnly: fmiOnly,
      shortFileThreshold: shortFileThreshold);
  Timer timer = new Timer();
  int count = -1;
  for (File f in fList) {
    count++;
    log.info('$count $f');
    var path = f.path;
    var fileExt = p.extension(path);
    if (fileExt == "" || fileExt == fileExt) {
      log.debug('Reading $path');
      var r = readWriteFileTiming(f);
      log.info('${r.info}');
      rSet.add(r);
      if (count % 100 == 0) {
        log.info(rSet);
        var n = '${count.toString().padLeft(6, " ")}';
        print('$n: $rSet ${timer.elapsed}: +$timer.split ');
      }
    }
  }
  timer.stop();
  rSet.duration = timer.elapsed;
  log.info('${rSet.info}');
  rSet.writeTSMap();
  return rSet;
}
