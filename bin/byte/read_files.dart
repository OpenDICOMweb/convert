// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';

final Logger log =
    new Logger("io/bin/read_files.dart", watermark: Severity.info);

void main() {
  for (String path in testPaths) {
      File f = new File(path);
      readCheck(f, fmiOnly: false);
  }
}

bool readCheck(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.config('Reading: $file with ${bytes0.lengthInBytes} bytes');
  log.down;
  if (bytes0 == null) return false;
  RootByteDataset rds0 = ByteReader.readBytes(bytes0, path: file.path, fast: true);
  print('rds0 root: ${rds0.root}');
  print('ParseInfo: ${rds0.parseInfo}');
  if (rds0 == null) return false;
  log.info('${rds0.parseInfo}');
  log.info('  Dataset: $rds0');
  log.up;
  return true;
}

//TODO: merge with read_write_files
bool readWriteCheck(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.config('Reading: $file with ${bytes0.lengthInBytes} bytes');
  log.down;
  if (bytes0 == null) return false;
  RootByteDataset rds0 =
      ByteReader.readBytes(bytes0, path: file.path, fast: true);
  print('rds0 root: ${rds0.root}');
  print('ParseInfo: ${rds0.parseInfo}');
  ByteElement e = rds0[0x00020010];
  print('e: $e');
  if (rds0 == null) return false;
  log.info('  Original: $rds0');

  /*
  Uint8List bytes1 = ByteWriter.writeBytes(rds0, fast: true);
  if (bytes1 == null) return false;
  if (!bytesEqual(bytes0, bytes1))
    print('********* Files are not equal!');
  RootByteDataset rds1 =
      ByteReader.readBytes(bytes1, path: file.path, fast: true);
  log.info('      Copy: $rds1');
  */
  log.up;
  //return rds0 == rds1;
  return true;
}


