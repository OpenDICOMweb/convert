// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/byte_convert.dart';
import 'package:system/server.dart';


//Urgent: use badFileList2 - fix indentation

void main() {
	Server.initialize(name: 'read_files.dart', level: Level.debug3);
  print('Read Files');
  system.log.level = Level.info;
  final paths = testPaths0;

  final nFiles = testPaths0.length;
  final width = '$nFiles'.length;

  for (var i = 0; i < paths.length; i++) {
    log.reset;

    final n = getPaddedInt(i, width);
    final p = cleanPath(paths[i]);
    final f = new File(paths[i]);
    final nBytes = f.lengthSync();
    if (nBytes == 0) {
      log.info0('Skipping empty file: $f');
    }
    log.config('$n: Reading: $p - $nBytes bytes');

    try {
      readCheck(f, i, fmiOnly: false);
    } on ShortFileError catch (e) {
      log..warn('ShortFile: $e')..warn('Short File(${f.lengthSync()} bytes): $f');
    } catch (e) {
      log.error(e);
      rethrow;
    }
  }
}

bool readCheck(File file, int fileNo, {int reps = 1, bool fmiOnly = false}) {
	final rds = ByteDatasetReader.readFile(file);
  if (rds == null) {
    log.warn('---  File not readable');
  } else {
    log..info0('${rds.parseInfo.info}')
    ..debug('Bytes Dataset: ${rds.info}');
  }
  log.info0('---\n');
  return (rds == null) ? false : true;
}

//TODO: merge with read_write_files
bool readWriteCheck(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  final Uint8List bytes0 = file.readAsBytesSync();
  log.config('Reading: $file with ${bytes0.lengthInBytes} bytes', 1);

  if (bytes0 == null) return false;
  final rds0 = ByteDatasetReader.readBytes(bytes0, path: file.path, fast: true);
  log..debug('rds0 root: ${rds0.root}')
  ..debug('ParseInfo: ${rds0.parseInfo}');
  final e = rds0[0x00020010];
  log.debug('e: $e');
  if (rds0 == null) return false;
  log.info0('  Original: $rds0', -1);
  return true;
}
