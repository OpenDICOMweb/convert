// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:core/server.dart';
import 'package:convert/convert.dart';

// This import contains a bunch of predefined paths
import 'package:convert/data/test_files.dart';


void main() {
  Server.initialize(name: 'ReadFile', level: Level.info, throwOnError: true);

  final path = path1; //test6684_02;
  log.info0('TagReader: $path');
  final rds0 = TagReader.readPath(path);
  log.info('${rds0.summary}');
}
