// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:core/server.dart';
import 'package:convert/convert.dart';

// This import contains a bunch of predefined paths
import 'package:convert/data/test_files.dart';

const String f6684a =
    'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';

void main() {
  Server.initialize(name: 'ReadFile', level: Level.info, throwOnError: true);

  final path = f6684a;
  log.info0('TagReader: $path');
  final rds0 = TagReader.readPath(path, doLogging: true);
  rds0.format(new Formatter.basic());
  log.info('${rds0.summary}');
}
