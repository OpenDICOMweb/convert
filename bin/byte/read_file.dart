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

final Logger log = new Logger("io/bin/read_files.dart", watermark: Severity.debug2);

void main() {
  var path = test6684_01;
  var f = new File(path);

  log.debug('Reading: $path');
  Uint8List bytes0 = f.readAsBytesSync();
  log.config('Reading: $f with ${bytes0.lengthInBytes} bytes');

  if (bytes0 == null) log.info('Invalid file: $f');
  RootByteDataset rds0 = ByteReader.readBytes(bytes0, path: path, fast: true);
  log.info('${rds0.parseInfo}');
  log.info('  Dataset: ${rds0.info}');
}

