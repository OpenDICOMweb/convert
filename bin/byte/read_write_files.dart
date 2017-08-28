// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:system/system.dart';

import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/server.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

void main() {
  Server.initialize(name: 'read_write_file', level: Level.info);

  // *** Modify [paths] value to read/write a different file
  List<String> paths = <String>[];
  //paths.addAll(testPaths0);
 // paths.addAll(testPaths1);
 // paths.addAll(testPaths2);
   paths.addAll(testErrors);

  for (int i = 0; i < paths.length; i++) {
    byteReadWriteFileChecked(paths[i], i);
  }
}

