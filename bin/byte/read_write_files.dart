// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:system/core.dart';

import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/byte_convert.dart.old';
import 'package:system/server.dart';


void main() {
  Server.initialize(name: 'read_write_file', level: Level.info1, throwOnError: true);

  // *** Modify [paths] value to read/write a different file
  final paths = testEvrPaths;

  for (var i = 0; i < paths.length; i++) {
    byteReadWriteFileChecked(paths[i], fileNumber: i);
  }
}
