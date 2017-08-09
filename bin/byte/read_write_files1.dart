// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_directories.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/compare_bytes.dart';
import 'package:dictionary/dictionary.dart';
import 'package:path/path.dart' as p;

import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';

import 'read_utils.dart';
import 'package:dcm_convert/src/dcm/byte_read_utils.dart';

final Logger log =
    new Logger("convert/bin/read_write_files1.dart", Level.debug2);

void main() {
  DcmReader.log.level = Level.info;
  DcmWriter.log.level = Level.info;
 // String testFile = test6684_02;
 // String testDir = dir36_4485_6684;
  assert(test6684_02 != null);
  assert(dir36_4485_6684 != null);

  // readWritePath(test6684_01, reps: 1, fmiOnly: false);
  // readWriteFileTimed(file, reps: 1, fast: false, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
    readWriteFiles(testPaths, fmiOnly: false);
  // readWriteDirectory(dir36_4485_6684, fast: false, throwOnError: true);
  //targetTS: TransferSyntaxUid.kImplicitVRLittleEndian);
}

void readWriteFiles(List<String> paths, {bool fmiOnly = false}) {
  for (String path in paths) readWriteFileTiming(new File(path));
}

final String tempDir = Directory.systemTemp.path;
final Stopwatch watch = new Stopwatch();

//TODO: move to common/constants.dart or elsewhere
const int kMB = 1024 * 1024;

bool readWritePath(String path, {int reps = 1, bool fmiOnly = false}) {
  File inFile = new File(path);
  return readWriteFile(inFile);
}

bool readWriteFile(File inFile, {int reps = 1, bool fmiOnly = false}) {
  Uint8List bytes0 = inFile.readAsBytesSync();
  ByteReader reader = new ByteReader(bytes0.buffer.asByteData());
  RootByteDataset rds0 = reader.readRootDataset();
/*  List<int> elementIndex0 = reader.elementIndex;*/
  log.info(rds0.parseInfo);
  log.info(rds0.info);

  ByteWriter writer = new ByteWriter(rds0);
  Uint8List bytes1 = writer.writeRootDataset();

/*  List<int> elementIndex1 = writer.elementIndex.sublist(0, writer.nthElement);
  if (reader.nthElement != writer.nthElement)
    print('reader: ${reader.nthElement}, writer: ${writer.nthElement}');
  for (int i = 0; i < reader.nthElement; i++)
    if (elementIndex0[i] != elementIndex1[i])
      print('$i: ${elementIndex0[i]} != ${elementIndex1[i]}');*/
  RootByteDataset rds1 = ByteReader.readBytes(bytes1);
  log.info(rds1.parseInfo);
  log.info(rds1.info);
  bool areDatasetsEqual = _compareDatasets(rds0, rds1);
  log.info('$rds0 == $rds1: $areDatasetsEqual');
  bool areBytesEqual = _bytesEqual(bytes0, bytes1, true);
  log.info('bytes0 == bytes1: $areBytesEqual');
  return null;
}


/* Flush if not used - but compare with readWrietFileTiming first
  bool readWriteFileTimed(File inFile, {int reps = 1, bool fmiOnly = false}) {
  *//* create a version of fPrint that does this stuff
  String mbps(int lib, int us) => (lib / us).toStringAsFixed(1);
  *//*
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
    RootByteDataset rds0 = ByteReader.readBytes(bytes0);
    Duration readDS0 = timer.split;

    Uint8List bytes1 = writeTimed(rds0);
    Duration writeDS0 = timer.split;

    //  RootByteDataset rds1 =
    ByteReader.readBytes(bytes1);
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
}*/

FileResult readWritePathTiming(String path, {int reps = 1, bool fmiOnly = false}) {
  File file = new File(path);
  return readWriteFileTiming(file);
}

FileResult readWriteFileTiming(File file,
    {bool fmiOnly = false,
    TransferSyntaxUid targetTS,
    bool throwOnError = false,
    bool writeOutputFile = false,
    bool shouldCompareDatasets = true}) {
  var path = file.path;
  var base = p.basename(path);
  var outPath = '$tempDir/$base';
  var outFile = new File(outPath);
  var outFileCreated = false;
  var hasProblem = false;
  FileResult result;

  try {
    Timer timer = new Timer();

    var start = timer.elapsed;
    Uint8List bytes0 = file.readAsBytesSync();
    var readBD = timer.elapsed;

    if (bytes0 == null) {
      log.error('Could not read "$path"');
      watch.stop();
      return null;
    }

    var rds0 = ByteReader.readBytes(bytes0);
    var readDS0 = timer.elapsed;
    var bytes1 = writeTimed(rds0, path: path);
    var writeDS0 = timer.elapsed;

    var rds1 = ByteReader.readBytes(bytes1);
    var readDS1 = timer.elapsed;

    //TODO: make this work?
    Duration compareDS;
    if (shouldCompareDatasets) {
      var v = _compareDatasets(rds0, rds1);
      compareDS = timer.elapsed;
      if (!v) {
        log.error('Unequal datasets:/n'
            '  rds0: ${rds0.total}/n'
            '  rds1: ${rds1.total}/n');
        hasProblem = true;
      }
    }

    var v = _bytesEqual(bytes0, bytes1, throwOnError);
    var stop = timer.elapsed;
    if (!v) hasProblem = true;

    var times = new FileTiming(
        file, start, stop, readBD, readDS0, writeDS0, readDS1, compareDS);

    result = new FileResult(file, rds0,
        fmiOnly: fmiOnly,
        targetTS: targetTS,
        times: times,
        hasProblem: hasProblem);

    /* Flush if not needed
    if (writeOutputFile) {
      outFile.writeAsBytesSync(bytes1);
      Duration writeBD = getElapsed();
      outFileCreated = true;

      Uint8List bytes2 = outFile.readAsBytesSync();
      Duration readBD2 = getElapsed();

      RootByteDataset rds2 = ByteReader.readBytes(bytes1);
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

bool _compareDatasets(RootByteDataset rds0, RootByteDataset rds1,
    [bool throwOnError = true]) {
  var v = compareByteDatasets(rds0, rds1, throwOnError);
  if (!v) {
    log.error('Unequal datasets:/n'
        '  rds0: ${rds0.total}/n'
        '  rds1: ${rds1.total}/n');
    return false;
  }
  return true;
}

bool _bytesEqual(Uint8List b0, Uint8List b1, [bool throwOnError]) {
  var v = bytesEqual(b0, b1);
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
    {bool fast: true,
    bool fmiOnly = false,
    bool throwOnError = true,
    String fileExt = '.dcm',
    int shortFileThreshold = 1024}) {
  var dir = new Directory(path);
  var fList = dir.listSync(recursive: true);
  fList.retainWhere((fse) => fse is File);
  var fileCount = fList.length;
  log.info('$fileCount files');

  //TODO: make this work
  var errFile = new File('bin/byte/errors.log');
  errFile.openWrite(mode: FileMode.WRITE_ONLY_APPEND);
  var startTime = new DateTime.now();

  log.info('Reading $path ...\n'
      '    with $fileCount files\n'
      '    at $startTime');

  var rSet = new ResultSet(dir, fList.length,
      fmiOnly: fmiOnly, shortFileThreshold: shortFileThreshold);
  var timer = new Timer();
  var count = -1;
  for (File f in fList) {
    count++;
    log.info('$count $f');
    var path = f.path;
    var fileExt = p.extension(path);
    if (fileExt == "" || fileExt == fileExt) {
      log.debug('Reading $path');

      FileResult r = (fast) ? readWriteFile(f) : readWriteFileTiming(f);
      if (r != null) {
        log.info('${r.info}');
        rSet.add(r);
        if (count % 100 == 0) {
          log.info(rSet);
          var n = '${count.toString().padLeft(6, " ")}';
          print('$n: $rSet ${timer.elapsed}: +$timer.split ');
        }
      }
    }
  }
  timer.stop();
  rSet.duration = timer.elapsed;
  log.info('${rSet.info}');
  rSet.writeTSMap();
  return rSet;
}
