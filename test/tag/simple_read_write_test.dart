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

import '../test_data.dart';
import '../test_utils.dart';

void main() {
  Server.initialize(
      name: 'dcm_reader_test', level: Level.info, throwOnError: true);

  const doLogging = true;

  group('Tag Simple Read', () {
       test('Tag Read/Write/Read', () {
      activeStudies.clear();

      allowZeroAges = true;
      allowBlankDates = true;
      allowInvalidNumberOfValues = true;
      allowInvalidValueLengths = true;
      allowOversizedStrings = true;
      allowInvalidCharsInStrings = true;
      allowInvalidSex = true;

      doRemoveBlankStrings = true;
      doTrimWhitespace = true;

      for (var path in [path8]) {
        final rds = readTagPath(path, doLogging: doLogging);
        log.debug('${rds.info}');
        final entity = activeStudies.entityFromRootDataset(rds);
        log.debug('${entity.info}');

        final outPath = getVNAPath(rds, 'bin/output/', 'dcm');
        final outBytes = TagWriter.writeBytes(rds, doLogging: true);

        final length = outBytes.length;
        log
          ..info('${rds.dsBytes}')
          ..info('outPath: $outPath')
          ..info('Output length: $length(${length ~/ 1024}K)')
          ..info('done');

        final rds1 = TagReader.readBytes(outBytes, doLogging: true);
        log.info('${rds1.info}');
      }
    });
  });
}
