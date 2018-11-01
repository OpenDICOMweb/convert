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
      name: 'ByteReader Test', throwOnError: true, level: Level.info);

  const doLogging = true;
  const stopOnError = true;
  allowZeroAges = true;
  allowBlankDates = true;

  final files = listFile();
  print('Reading ${files.length} files ...');

  test('read_write_read files', () {

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final rds0 = readBytePath(file, doLogging: doLogging);
        if (rds0 == null) {
          log.warn('Invalid DICOM file: ${rds0.path}');
        } else {
          if (doLogging) log.info('${rds0.summary}');
        }

        final outPath = getVNAPath(rds0, 'bin/output/', 'dcm');
        final output = ByteWriter.writeBytes(rds0, doLogging: doLogging);

        final length = output.length;
        if (doLogging) {
          log..info('${rds0.dsBytes}')..info('outPath: $outPath')..info(
              'Output length: $length(${length ~/ 1024}K)')..info('done');
        }

        expect(output.isNotEmpty, true);
        expect(output.limit == output.length, true);
        expect(length == output.buffer.lengthInBytes, true);
        expect(length == output
            .asByteData()
            .lengthInBytes, true);
        expect(output.asUint8List(), equals(output.buffer.asUint8List()));
        expect(output.elementSizeInBytes == 1, true);
        expect(output.offset == output
            .asByteData()
            .offsetInBytes, true);
//        expect(output.vrIndex == vrIndexByCode8Bit[output.vrCode], true);
        expect(output.asInt8List(), equals(output.buffer.asInt8List()));

        final rds1 = ByteReader.readBytes(output, doLogging: doLogging);
        if (rds1 == null) {
          log.warn('Invalid DICOM file: $outPath');
        } else {
          if (doLogging) log.info('${rds1.summary}');
        }

        final result = rds0 == rds1;
        if (doLogging) print(result ? '** Success' : '**** Failure ****');

        final source = rds0.dsBytes.bytes;
        if (!bytesEqual1(source, output))
          print('Source: $source != Output: $output');

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
