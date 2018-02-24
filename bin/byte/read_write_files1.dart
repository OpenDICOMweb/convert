// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:path/path.dart' as p;
import 'package:core/server.dart';

import 'package:convert/data/test_directories.dart';
import 'package:convert/data/test_files.dart';

//TODO: move to appropriate place
import 'read_utils.dart';

const String foo = 'C:/odw/test_data/mweb/ASPERA/'
		'DICOM filesonly/22c82bd4-6926-46e1-b055-c6b788388014.dcm';
void main() {
  Server.initialize(name: 'read_write_file.dart', level: Level.debug);
  // String testFile = test6684_02;
  // String testDir = dir36_4485_6684;
  assert(test6684_02 != null);
  assert(dir36_4485_6684 != null);

  // readWritePath(test6684_01, reps: 1, fmiOnly: false);
  // readWriteFileTimed(file, reps: 1, fast: false, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  readWriteFiles([foo], fmiOnly: false);
  // readWriteDirectory(dir36_4485_6684, fast: false, throwOnError: true);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

void readWriteFiles(List<String> paths, {bool fmiOnly = false}) {
  for (var path in paths) readWriteFileTiming(new File(path));
}

final String tempDir = Directory.systemTemp.path;
final Stopwatch watch = new Stopwatch();

//TODO: move to common/constants.dart or elsewhere
const int kMB = 1024 * 1024;

bool readWritePath(String path, {int reps = 1, bool fmiOnly = false}) {
  final inFile = new File(path);
  return readWriteFile(inFile);
}

bool readWriteFile(File inFile, {int reps = 1, bool fmiOnly = false}) {
  final Uint8List bytes0 = inFile.readAsBytesSync();
  final reader = new BDReader.fromTypedData(bytes0);
  final rds0 = reader.readRootDataset();
/*  List<int> elementIndex0 = reader.elementIndex;*/
  log..info0(rds0.pInfo)..info0(rds0.info);

  final writer = new BDWriter(rds0);
  final bytes1 = writer.writeRootDataset();

/*  List<int> elementIndex1 = writer.elementIndex.sublist(0, writer.nthElement);
  if (reader.nthElement != writer.nthElement)
    print('reader: ${reader.nthElement}, writer: ${writer.nthElement}');
  for (int i = 0; i < reader.nthElement; i++)
    if (elementIndex0[i] != elementIndex1[i])
      print('$i: ${elementIndex0[i]} != ${elementIndex1[i]}');*/
  final rds1 = BDReader.readBytes(bytes1);
  log..info0(rds1.pInfo)..info0(rds1.info);
  final areDatasetsEqual = _compareDatasets(rds0, rds1);
  log.info0('$rds0 == $rds1: $areDatasetsEqual');
  final areBytesEqual = uint8ListEqual(bytes0, bytes1.asUint8List());
  log.info0('bytes0 == bytes1: $areBytesEqual');
  return areDatasetsEqual && areBytesEqual;
}

FileResult readWritePathTiming(String path, {int reps = 1, bool fmiOnly = false}) {
  final file = new File(path);
  return readWriteFileTiming(file);
}

FileResult readWriteFileTiming(File file,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    bool throwOnError = false,
    bool writeOutputFile = false,
    bool shouldCompareDatasets = true}) {
  final path = file.path;
  final base = p.basename(path);
  final outPath = '$tempDir/$base';
  final outFile = new File(outPath);
  final outFileCreated = false;
  var hasProblem = false;
  FileResult result;

  try {
    final timer = new Timer();

    final start = timer.elapsed;
    final bytes0 = file.readAsBytesSync();
    final readBD = timer.elapsed;

    if (bytes0 == null) {
      log.error('Could not read "$path"');
      watch.stop();
      return null;
    }

    final rds0 = BDReader.readBytes(bytes0);
    final readDS0 = timer.elapsed;
    final bytes1 = writeTimed(rds0, path: path);
    final writeDS0 = timer.elapsed;

    final rds1 = BDReader.readBytes(bytes1);
    final readDS1 = timer.elapsed;

    //TODO: make this work?
    Duration compareDS;
    if (shouldCompareDatasets) {
      final v = _compareDatasets(rds0, rds1);
      compareDS = timer.elapsed;
      if (!v) {
        log.error('Unequal datasets:/n'
            '  rds0: ${rds0.total}/n'
            '  rds1: ${rds1.total}/n');
        hasProblem = true;
      }
    }

    final v = _bytesEqual(bytes0, bytes1, throwOnError);
    final stop = timer.elapsed;
    if (!v) hasProblem = true;

    final times =
        new FileTiming(file, start, stop, readBD, readDS0, writeDS0, readDS1, compareDS);

    result = new FileResult(file, rds0,
        fmiOnly: fmiOnly, targetTS: targetTS, times: times, hasProblem: hasProblem);
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

bool _compareDatasets(BDRootDataset rds0, BDRootDataset rds1,
    [bool throwOnError = true]) {
  final v = compareByteDatasets(rds0, rds1);
  if (!v) {
    log.error('Unequal datasets:/n'
        '  rds0: ${rds0.total}/n'
        '  rds1: ${rds1.total}/n');
    return false;
  }
  return true;
}

bool _bytesEqual(Bytes b0, Bytes b1, [bool throwOnError]) {
  final v = bytesEqual(b0, b1);
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
  final dir = new Directory(path);
  final fList = dir.listSync(recursive: true)..retainWhere((fse) => fse is File);
  final fileCount = fList.length;
  log.info0('$fileCount files');

  //TODO: make this work
  new File('bin/byte/errors.log')..openWrite(mode: FileMode.WRITE_ONLY_APPEND);
  final startTime = new DateTime.now();

  log.info0('Reading $path ...\n'
      '    with $fileCount files\n'
      '    at $startTime');

  final rSet = new ResultSet(dir, fList.length,
      fmiOnly: fmiOnly, shortFileThreshold: shortFileThreshold);
  final timer = new Timer();
  var count = -1;
  for (File f in fList) {
    count++;
    log.info0('$count $f');
    final path = f.path;
    final fileExt = p.extension(path);
    if (fileExt == '' || fileExt == fileExt) {
      log.debug('Reading $path');

      final FileResult r = (fast) ? readWriteFile(f) : readWriteFileTiming(f);
      if (r != null) {
        log.info0('${r.info}');
        rSet.add(r);
        if (count % 100 == 0) {
          log.info0(rSet);
          final n = '${count.toString().padLeft(6, " ")}';
          print('$n: $rSet ${timer.elapsed}: +$timer.split ');
        }
      }
    }
  }
  timer.stop();
  rSet.duration = timer.elapsed;
  log.info0('${rSet.info}');
  rSet.writeTSMap();
  return rSet;
}
