// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:core/system.dart';
import 'package:dcm_convert/data/test_files.dart';
//import 'package:dcm_convert/data/test_directories.dart';

import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';
import 'package:dcm_convert/src/dcm/byte_read_utils.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

void main() {
  //TODO: fix logger so next two lines are unnecessary
  DcmReader.log.level = Level.info;
  DcmWriter.log.level = Level.info;
  log.level = Level.info;

  // *** Modify [paths] value to read/write a different file
  List<String> paths = <String>[];
  paths.addAll(testPaths);
 // paths.addAll(testErrors);
 // paths. addAll(testData);
 // paths.addAll(fileList2);
 // paths.addAll(fileList3);


  for (int i = 0; i < paths.length; i++) {
    byteReadWriteFileChecked(paths[i], i);
  }
}

