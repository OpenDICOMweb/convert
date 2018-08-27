//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:converter/converter.dart';
import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

const String path0 = 'C:/odw_test_data/mweb/TransferUIDs'
    '/1.2.840.10008.1.2.5.dcm';

void main() {
  Server.initialize(name: 'ByteReader Test',
      throwOnError: true,
      level: Level.debug);

    test('ByteReader Read file', () {
      global.allowBlankDateTimes = true;
      final rds = ByteReader.readPath(path0);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });
}
