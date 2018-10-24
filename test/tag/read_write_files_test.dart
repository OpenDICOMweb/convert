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

import '../../test/test_utils.dart';

void main() {
  Server.initialize(
      name: 'TagReader Test', throwOnError: true, level: Level.debug2);

  const doLogging = true;
  const stopOnError = false;
  final files = listFile();
  print('Reading ${files.length} files ...');
  /// Allow Ages == 0
  allowZeroAges = true;
  allowBlankDates = true;
  allowOversizedStrings = true;
  allowInvalidCharsInStrings = true;
  allowInvalidVMs = true;

  test('read_write_read files', () {

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final rds0 = readTagPath(file, doLogging: doLogging);
        if (rds0 == null) {
          log.warn('Invalid DICOM file: ${rds0.path}');
        } else {
          if (doLogging) log.info('${rds0.summary}');
        }

        final outPath = getVNAPath(rds0, 'bin/output/', 'dcm');
        final outBytes = TagWriter.writeBytes(rds0, doLogging: doLogging);

        final length = outBytes.length;
        if (doLogging) {
          log..info('${rds0.dsBytes}')..info('outPath: $outPath')..info(
              'Output length: $length(${length ~/ 1024}K)')..info('done');
        }

        expect(outBytes.isNotEmpty, true);
        expect(outBytes.limit == outBytes.length, true);
        expect(length == outBytes.buffer.lengthInBytes, true);
        expect(length == outBytes
            .asByteData()
            .lengthInBytes, true);
        expect(outBytes.asUint8List(), equals(outBytes.buffer.asUint8List()));
        expect(outBytes.elementSizeInBytes == 1, true);
        expect(outBytes.offset == outBytes
            .asByteData()
            .offsetInBytes, true);
        expect(outBytes.vrIndex == vrIndexByCode8Bit[outBytes.vrCode], true);
        expect(outBytes.asInt8List(), equals(outBytes.buffer.asInt8List()));

        final rds1 = TagReader.readBytes(outBytes, doLogging: doLogging);
        if (rds1 == null) {
          log.warn('Invalid DICOM file: $outPath');
        } else {
          if (doLogging) log.info('${rds1.summary}');
        }

        final result = rds0 == rds1;
        if (doLogging) print(result ? '** Success' : '**** Failure ****');

        if (result)
          expect(rds0 == rds1, true);
        else
          expect(rds0 == rds1, false);
        // ignore: avoid_catches_without_on_clauses
      } catch (e, trace) {
        print('Error: "$file"');
        print('Stack: $trace');
        if (stopOnError) rethrow;
      }
    }
    print('Tested ${files.length} files');
  });
}
