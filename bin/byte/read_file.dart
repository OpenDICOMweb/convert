// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:system/system.dart';
import 'package:dcm_convert/dcm.dart';

import 'package:dcm_convert/data/test_files.dart';

var pathx ='c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';
//Urgent: bug with path20
void main() {
  System.log.level = Level.debug2;

  var path = path22;

  log.config('Byte Reader: $path');
  log.config('System: $System');
  log.config('system: $system');
  RootByteDataset rds = ByteReader.readPath(path);
  if (rds == null) {
    log.warn('Invalid DICOM file: $path');
  } else {
    log.info0('${rds.parseInfo.info}');
    log.info0('Bytes Dataset: ${rds.summary}');
  }
}
