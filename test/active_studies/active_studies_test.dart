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
      name: 'ByteReader Test', throwOnError: false, level: Level.info);

  const doLogging = true;
  final files = listFile();
  print('Reading ${files.length} files ...');

  test('read_files', () {
    print('${activeStudies.summary}\n');

    for (var i = 0; i < files.length; i++) {
      final rds = readPath(files[i], doLogging: doLogging);

      log.debug('\n${rds.info}');
      if (rds == null) {
        log.warn('Invalid DICOM file: ${rds.path}');
      } else {
        log.debug('rds0.summary: ${rds.summary}');
        expect(rds.isNotEmpty, true);
        // expect(rds0.elements.length != 0, true);
        expect(rds.duplicates, <int>[]);
        // expect(rds.nPrivateElements != 0, true);
        expect(rds.lengthInBytes == rds.dsBytes.vfLength, true);
        expect(rds.prefix == rds.dsBytes.prefix, true);
        expect(rds.preamble == rds.dsBytes.preamble, true);
        expect(rds.isEvr == rds.transferSyntax.isEvr, true);
        expect(rds.isIVR == rds.transferSyntax.isIvr, true);
        expect(rds.duplicates == rds.history.duplicates, true);
        if (rds.pixelData != null) {
          expect(rds.pixelRepresentation >= 0, true);
          expect(rds.samplesPerPixel >= 1, true);
          expect(rds.photometricInterpretation, isNotNull);
          expect(rds.rows, isNotNull);
          expect(rds.columns, isNotNull);
          expect(rds.bitsAllocated, isNotNull);
          expect(rds.bitsStored, isNotNull);
          expect(rds.highBit, isNotNull);
        }
      }

     // final Instance entity = ActiveStudies.addSopInstance(rds);
    //  print('${entity.study.summary}\n');
    }
//    print('${activeStudies.summary}\n');
//    for (var study in activeStudies.studies) print('${study.summary}');
    print('studies(${activeStudies.studies.length}):\n  '
        '${activeStudies.studies.toList().join('\n  ')}');
    print('series(${activeStudies.series.length}):\n  '
        '${activeStudies.series.toList().join('\n  ')}');
    print('instances(${activeStudies.instances.length}):\n  '
        '${activeStudies.instances.toList().join('\n  ')}');
  });
}
