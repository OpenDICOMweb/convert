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
      name: 'dcm_reader_test', level: Level.debug2, throwOnError: true);

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
  const path5 = 'C:/odw_test_data/6684/2017/5/13/4/888A5773/2463BF1A/2463C2DB';
  const path6 = 'C:/odw_test_data/mweb/ASPERA/DICOM files only/'
      '22f01f4d-32c0-4a13-9350-9f0b4390889b.dcm';
  const path7 = 'C:/odw_test_data/mweb/Sample Dose Sheets/'
      '4cfc6ccc-2a8c-4af4-beb6-c4968fbb10d0.dcm';

  // Implicit Little Endian
  const path8 = 'C:/odw_test_data/mweb/Sample Dose Sheets/'
      '1d7fa0b8-06a7-4eef-9486-9e3ac3347eae.dcm';

  // Urgent Jim: read error here
  const path9 = ' C:/odw_test_data/mweb/Sample Dose Sheets/'
      '4e627a0a-7ac2-4c44-8a3e-6515951fc6bb.dcm';
  const path10 = 'C:/odw_test_data/mweb/500+/'
      'PET PETCT_CTplusFET_LM_Brain (Adult)/'
      'dynamic recon 3x10min Volume (Corrected) - 7/IM-0001-0218.dcm';

  const doLogging = true;
  allowInvalidSex = true;

  group('Simple Read Tests', () {
    test('Path0', () {
      final rds = readBytePath(path10, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = ActiveStudies.addSopInstance(rds);
      log.debug('${entity.info}');
    });

    test('Path1', () {
      final rds = readBytePath(path1, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path2', () {
      allowBlankDates = true;
      final rds = readBytePath(path2, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path3', () {
      final rds = readBytePath(path3, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });

    test('Path4', () {
      final rds = readBytePath(path4, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');

      final outPath = getVNAPath(rds, 'bin/output/', 'dcm');
      final outBytes = ByteWriter.writeBytes(rds, doLogging: doLogging);

      final length = outBytes.length;
      log
        ..info('${rds.dsBytes}')
        ..info('outPath: $outPath')
        ..info('Output length: $length(${length ~/ 1024}K)')
        ..info('done');

      final rds1 = ByteReader.readBytes(outBytes, doLogging: doLogging);
      log.info('${rds1.info}');
    });

    test('Path5', () {
      final rds = readBytePath(path5, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = ActiveStudies.addSopInstance(rds);
      log.debug('${entity.info}');
    });

    test('Path6', () {
      final rds = readBytePath(path6, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = ActiveStudies.addSopInstance(rds);
      log.debug('${entity.info}');
    });

    test('Path7', () {
      final rds = readBytePath(path7, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');

      final outPath = getVNAPath(rds, 'bin/output/', 'dcm');
      final outBytes = ByteWriter.writeBytes(rds, doLogging: doLogging);

      final length = outBytes.length;
      log
        ..info('${rds.dsBytes}')
        ..info('outPath: $outPath')
        ..info('Output length: $length(${length ~/ 1024}K)')
        ..info('done');

      final rds1 = ByteReader.readBytes(outBytes, doLogging: doLogging);
      log.info('${rds1.info}');
    });

    test('Path8', () {
      final rds = readBytePath(path8, doLogging: doLogging);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');

      final outPath = getVNAPath(rds, 'bin/output/', 'dcm');
      final output = ByteWriter.writeBytes(rds, doLogging: doLogging);

      final length = output.length;
      log
        ..info('${rds.dsBytes}')
        ..info('outPath: $outPath')
        ..info('Output length: $length(${length ~/ 1024}K)')
        ..info('done');

      final source = rds.dsBytes.bytes;
      print('Source: $source');
      print('Output: $output');
      if (source == output)
        print('Source: $source != Output: $output');

      final rds1 = ByteReader.readBytes(output, doLogging: doLogging);
      log.info('${rds1.info}');
    });
  });
}
