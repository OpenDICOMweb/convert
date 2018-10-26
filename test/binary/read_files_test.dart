//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

import '../../test/test_utils.dart';

void main() {
  Server.initialize(
      name: 'ByteReader Test', throwOnError: true, level: Level.warn1);

  const doLogging = false;
  const stopOnError = true;
  allowBlankDates = true;
  allowZeroAges = true;

  final files = listFile(dirMweb500);
  print('Reading ${files.length} files ...');

  test('read_files', () {
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final rds0 = readBytePath(file, doLogging: doLogging);
        if (rds0 == null) {
          log.warn('Invalid DICOM file: ${rds0.path}');
        } else if (rds0.fmi.isNotEmpty && rds0.isEmpty) {
          print('**** FMI Only: $file');
          return rds0;
        } else {
          log.debug('rds0.summary: ${rds0.summary}');

          //expect(rds0.elements.length != 0, true);
          expect(rds0.duplicates, <int>[]);
          // expect(rds0.nPrivateElements != 0, true);
          expect(rds0.lengthInBytes == rds0.dsBytes.vfLength, true);
          expect(rds0.prefix == rds0.dsBytes.prefix, true);
          expect(rds0.preamble == rds0.dsBytes.preamble, true);
          expect(rds0.isEvr == rds0.transferSyntax.isEvr, true);
          expect(rds0.isIVR == rds0.transferSyntax.isIvr, true);
          expect(rds0.duplicates == rds0.history.duplicates, true);
          final pixels = rds0.getPixelData();
          if (pixels != null) {
            expect(rds0.pixelRepresentation >= 0, true);
            expect(rds0.samplesPerPixel >= 1, true);
            expect(rds0.photometricInterpretation, isNotNull);
            expect(rds0.rows, isNotNull);
            expect(rds0.columns, isNotNull);
            //        expect(rds0.bitsAllocated, isNotNull);
            expect(rds0.bitsStored, isNotNull);
            expect(rds0.highBit, isNotNull);
          }
          log.debug('rds0.dsBytes: ${rds0.dsBytes}');
        }
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
