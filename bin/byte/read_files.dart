// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/system.dart';

final Logger log =
    new Logger("io/bin/read_files.dart", Level.config);

//Urgent: use badFileList2 - fix indentation

void main() {
  print('Read Files');
  System.log.level = Level.info;
  var paths = testPaths0;

  var nFiles = testPaths0.length;
  var width = '$nFiles'.length;

  for (int i = 0; i < paths.length; i++) {
    log.reset;

    var n = getPaddedInt(i, width);
    var p = cleanPath(paths[i]);
    File f = new File(paths[i]);
    var nBytes = f.lengthSync();
    if (nBytes == 0) {
      log.info0('Skipping empty file: $f');
    }
    log.config('$n: Reading: $p - $nBytes bytes');

    try {
      readCheck(f, i, fmiOnly: false);
    } on ShortFileError catch (e) {
      log.warn('ShortFile: $e');
      log.warn('Short File(${f.lengthSync()} bytes): $f');
    } catch (e) {
      log.error(e);
    }
  }
}

bool readCheck(File file, int fileNo, {int reps = 1, bool fmiOnly = false}) {
  var rds = ByteReader.readFile(file);
  if (rds == null) {
    log.warn('---  File not readable');
  } else {
    log.info0('${rds.parseInfo.info}');
    log.debug('Bytes Dataset: ${rds.info}');
  }
  log.info0('---\n');
  return (rds == null) ? false : true;
}

//TODO: merge with read_write_files
bool readWriteCheck(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.config('Reading: $file with ${bytes0.lengthInBytes} bytes', 1);

  if (bytes0 == null) return false;
  RootByteDataset rds0 =
      ByteReader.readBytes(bytes0, path: file.path, fast: true);
  log.debug('rds0 root: ${rds0.root}');
  log.debug('ParseInfo: ${rds0.parseInfo}');
  ByteElement e = rds0[0x00020010];
  log.debug('e: $e');
  if (rds0 == null) return false;
  log.info0('  Original: $rds0', -1);
  return true;
}
