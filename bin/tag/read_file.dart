// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:logger/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/byte_convert.dart';

final Logger log = new Logger('io/bin/read_files_old.dart', Level.info);

void main() {
  final path = path1; //test6684_02;
  log.info0('TagReader: $path');
  final rds0 = TagReader.readPath(path);
  log..info0('${rds0.pInfo}')..info0('TagDataset: ${rds0.info}');
}
