// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/byte_convert.dart';
import 'package:path/path.dart' as p;
import 'package:system/server.dart';
import 'package:timer/timer.dart';

//import 'package:dcm_convert/data/test_directories.dart';
import 'package:dcm_convert/data/test_files.dart';


void main() {
	Server.initialize(name: 'read_write_file.dart', level: Level.debug);

  readWriteFileFast(new File(path0), reps: 1, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readWriteFiles(paths, fmiOnly: false);
  //readWriteDirectory(mrStudy, fmiOnly: true);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

const int kMB = 1024 * 1024;

String mbps(int lib, int us) => (lib / us).toStringAsFixed(1);
String fmt(double v) => v.toStringAsFixed(1).padLeft(7, ' ');

final List<String> shortFiles = <String>[];
int shortFileMark = 1024;

bool readWriteFileFast(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  final bytes0 = file.readAsBytesSync();
  if (bytes0 == null) return false;
  if (bytes0.length <= shortFileMark) shortFiles.add('"${file.path}"');
  final rds0 = ByteReader.readBytes(bytes0, path: file.path);
  if (rds0 == null) return false;
  log.debug(rds0);
  final bytes1 = writeTimed(rds0);
  if (bytes1 == null) return false;
  return bytesEqual(bytes0, bytes1);
}

//TODO: cleanup timing
bool readWriteFileTimed(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  final timer = new Timer(start: true);

  final bytes0 = file.readAsBytesSync();
  final readBytes = timer.split;
  if (bytes0 == null) return false;
  if (bytes0.length <= shortFileMark) shortFiles.add('"${file.path}"');

  final rds0 = ByteReader.readBytes(bytes0, path: file.path);
  final parse = timer.split;
  if (rds0 == null) return false;

  final bytes1 = writeTimed(rds0);
  final writeDS = timer.split;

  if (bytes1 == null) return false;

  final areEqual = bytesEqual(bytes0, bytes1);
  final compare = timer.split;
  final total = timer.elapsed;
  final out = '''
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
  final dir = new Directory(path);
  final fList = dir.listSync(recursive: true)..retainWhere((fse) => fse is File);
  final fileCount = fList.length;
  log.config('$fileCount files');

  //TODO: make this work
  new File('bin/byte/errors.log')..openWrite(mode: FileMode.WRITE_ONLY_APPEND);
  final startTime = new DateTime.now();

  log.config('Reading $path ...\n'
      '    with $fileCount files\n'
      '    at $startTime\n'
      ' Count   Good    Bad Seconds        Elapsed');

  final timer = new Timer(start: true);
  var count = -1;
  var good = 0;
  var bad = 0;
  final badTS = <String>[];
  final badExt = <String>[];
  final errors = <String>[];

  for (File f in fList) {
    count++;
    if (count % printEvery == 0) currentStats(count, good, bad, timer);
    log.debug('$count length(${f.lengthSync() ~/ 1000}KB): $f');
    final path = f.path.replaceAll('\\', '/');
    final fileExt = p.extension(path);
    if (fileExt != ' ' && fileExt != ' .dcm') {
      log
        ..debug('fileExt: "$fileExt"')
        ..warn('Non DICOM file??? $path');
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
      } on InvalidTransferSyntax catch (e) {
        badTS.add('"${e.ts.asString}": "$path"');
        continue;
      } catch (e) {
        errors.add('"$path"');
        log..error(e)..error('  $f');
        v = false;
        bad++;
        if (throwOnError) rethrow;
      }
    }
  }
  timer.stop();
  currentStats(count, good, bad, timer);

  log
    ..config('Elapsed Time: ${timer.elapsed}')
    ..config('Map<String, String> badTS = <String, String>{${badTS.join(',\n')}};')
    ..config('List<String> badFileExtension = [${badExt.join(',\n')}];')
    ..config('List<String> errors = [ ${errors.join(',\n')}');
}

String padNumber(int n, [int width = 6, String padChar = ' ']) =>
    '${n.toString().padLeft(width, padChar)}';

void currentStats(int count, int good, int bad, Timer timer) {
  final seconds = timer.split.inMicroseconds / 1000;
  final now = timer.elapsed;
  final us = seconds.toStringAsFixed(3).padLeft(6, ' ');
  log.config('${padNumber(count)} ${padNumber(count)} '
      '${padNumber(count)} $us $now');
}
