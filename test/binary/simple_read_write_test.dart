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
import 'package:test_tools/tools.dart';

import '../test_utils.dart';

void main() {
  Server.initialize(
      name: 'dcm_reader_test', level: Level.info, throwOnError: true);

  const doLogging = true;

  group('Byte Simple Read/Write', () {
    test('Byte Read/Write/Read', () {
      activeStudies.clear();

      allowInvalidSex = true;
      allowZeroAges = true;

      for (var path in paths) {
        final rds = readBytePath(path, doLogging: doLogging);
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
      }
    });
  });
}
