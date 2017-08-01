// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';

final Logger log = new Logger("io/bin/read_files.dart", watermark: Severity.info);

void main() {
  var path = path1; //test6684_02;
  log.info('TagReader: $path');
  RootTagDataset rds0 = TagReader.readPath(path);
  log.info('${rds0.parseInfo}');
  log.info('TagDataset: ${rds0.info}');
}

