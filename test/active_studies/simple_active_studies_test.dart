//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

import '../test_data.dart';
import '../test_utils.dart';

import 'package:converter/src/binary/byte/reader/byte_reader.dart';

void main() {
  Server.initialize(
      name: 'dcm_reader_test', level: Level.info, throwOnError: true);

  const doLogging = true;

  group('Simple Active Studies Tests', () {
    test('Read', () {
      activeStudies.clear();

      allowInvalidSex = true;

      for (var path in paths) {
        final rds = readBytePath(path, doLogging: doLogging);
        log.debug('${rds.info}');
        final entity = activeStudies.entityFromRootDataset(rds);
        log.debug('${entity.info}');
        print('${entity.summary}\n');
        print('${activeStudies.summary}\n');
      }
    });
  });
}