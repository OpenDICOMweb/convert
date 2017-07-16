// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/compare_dataset.dart';

final Logger log = new Logger("io/bin/read_files.dart", watermark: Severity.info);

void main() {
  var path = path1; //test6684_02;
  log.info('Path: $path');

  log.info('ByteReader');
  RootByteDataset rbds0 = ByteReader.readPath(path);
  log.info('${rbds0.parseInfo}');
  log.info('Byte Dataset: ${rbds0.info}');

  log.info('TagReader');
  RootTagDataset rtds0 = TagReader.readPath(path);
  log.info('${rtds0.parseInfo}');
  log.info('Tag Dataset: ${rtds0.info}');

  //Urgent:
  compareDatasets(rbds0, rtds0);
}

