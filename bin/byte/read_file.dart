// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';

import 'package:dcm_convert/src/dcm/dcm_reader.dart';

//Urgent: problem file: path22
//Urgent: problem file: ivrFile
void main() {
  final log = new Logger("io/bin/read_files.dart", watermark: Severity.info);
  DcmReader.log.watermark = Severity.debug;

  var path = badFileList0[4];

  log.config('Byte Reader: $path');
  RootByteDataset rds = ByteReader.readPath(path);
  if (rds == null) {
    log.warn('No Data: $path');
  } else {
    log.info('${rds.parseInfo.info}');
    log.info('Bytes Dataset: ${rds.info}');
  }
}
