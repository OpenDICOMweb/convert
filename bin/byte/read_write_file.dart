// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

// Problem Files
//   1. fileList2
void main() {

  log.level = Level.debug3;
  DcmReader.log.level = Level.debug3;
  DcmWriter.log.level = Level.debug3;

  // *** Modify the [path0] value to read/write a different file
  var path = testPaths1[1];

  byteReadWriteFileChecked(path, 1, 5, true, true);
}
