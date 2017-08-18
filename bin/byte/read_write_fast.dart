// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:common/timer.dart';
import 'package:core/core.dart';
//import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/data/test_directories.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/compare_bytes.dart';
import 'package:path/path.dart' as p;

import 'package:dcm_convert/src/dcm/byte_read_utils.dart';

final Logger log = new Logger("convert/bin/read_write_files1.dart",
    Level.config);

void main() {
  //readWriteFileFast(new File(path0), reps: 1, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readWriteFiles(paths, fmiOnly: false);
  readWriteDirectory(mrStudy, fmiOnly: true);
  //targetTS: TransferSyntaxUid.kImplicitVRLittleEndian);
}

final String _tempDir = Directory.systemTemp.path;
final Stopwatch _watch = new Stopwatch();

const int kMB = 1024 * 1024;

String mbps(int lib, int us) => (lib / us).toStringAsFixed(1);
String fmt(double v) => v.toStringAsFixed(1).padLeft(7, ' ');

List<String> shortFiles = <String>[];
int shortFileMark = 1024;

bool readWriteFileFast(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  if (bytes0 == null) return false;
  if (bytes0.length <= shortFileMark) shortFiles.add('"${file.path}"');
  RootByteDataset rds0 = ByteReader.readBytes(bytes0, path: file.path);
  if (rds0 == null) return false;
  log.debug(rds0);
  Uint8List bytes1 = writeTimed(rds0);
  if (bytes1 == null) return false;
  return bytesEqual(bytes0, bytes1);
}

//TODO: cleanup timing
bool readWriteFileTimed(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  var timer = new Timer(start: true);

  Uint8List bytes0 = file.readAsBytesSync();
  var readBytes = timer.split;
  if (bytes0 == null) return false;
  if (bytes0.length <= shortFileMark) shortFiles.add('"${file.path}"');

  RootByteDataset rds0 = ByteReader.readBytes(bytes0, path: file.path);
  var parse = timer.split;
  if (rds0 == null) return false;

  var bytes1 = writeTimed(rds0);
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
  File errFile = new File('bin/byte/errors.log');
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
      log.warn('Non DICOM file??? $path');
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
