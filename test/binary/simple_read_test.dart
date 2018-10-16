//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
import 'package:converter/converter.dart';
import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

import '../test_utils.dart';

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
  const path4 = 'C:/odw_test_data/mweb/ASPERA/DICOM files only/'
      '22f01f4d-32c0-4a13-9350-9f0b4390889b.dcm';
  const path5 ='C:/odw_test_data/6684/2017/5/13/4/888A5773/2463BF1A/2463C2DB';

  const doLogging = true;

  group('Simple Read Tests', () {
    test('Path0', () {
      final rds = readPath(path0, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = ActiveStudies.addSopInstance(rds);
      log.debug('${entity.info}');
    });

    test('Path1', () {
      final rds = readPath(path1, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path2', () {
      final rds = readPath(path2, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path3', () {
      final rds = readPath(path3, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path4', () {
      final rds = readPath(path4, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');

      final outPath = getVNAPath(rds, 'bin/output/', 'dcm');
      final outBytes = ByteWriter.writeBytes(rds, doLogging: false);

      final length = outBytes.length;
      log
        ..info('${rds.dsBytes}')
        ..info('outPath: $outPath')
        ..info('Output length: $length(${length ~/ 1024}K)')
        ..info('done');

      final rds1 = ByteReader.readBytes(outBytes, doLogging: false);
      log.info('${rds1.info}');
    });

    test('Path5', () {
      final rds = readPath(path5, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = ActiveStudies.addSopInstance(rds);
      log.debug('${entity.info}');
    });
  });
}
