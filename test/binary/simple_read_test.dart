//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

import 'package:converter/src/binary/byte/reader/byte_reader.dart';

void main() {
  Server.initialize(
      name: 'dcm_reader_test', level: Level.debug, throwOnError: true);

  const path0 = 'C:/odw_test_data/mweb/10 Patient IDs'
      '/2a5bef0f-e4d2-4680-bd24-f42d902d6741.dcm';
  const path1 = 'C:/odw_test_data/mweb/TransferUIDs'
      '/1.2.840.10008.1.2.4.100.dcm';
  const path2 = 'C:/odw_test_data/mweb/TransferUIDs'
      '/1.2.840.10008.1.2.5.dcm';
  const path3 = 'C:/odw_test_data/mweb/ASPERA/'
      'Clean_Pixel_test_data/RTOG Study/'
      'RTP_2.25.369465182237858466013782274173253459938.1.dcm';

  group('Simple Read Tests', () {

    test('Path0', () {
      final rds = ByteReader.readPath(path0);
      log.debug('${rds.info}');
      final entity = ActiveStudies.addSopInstance(rds);
      log.debug('${entity.info}');
    });

    test('Path1', () {
      final rds = ByteReader.readPath(path1);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path2', () {
      final rds = ByteReader.readPath(path2);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path3', () {
      final rds = ByteReader.readPath(path3);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });
  });
}
