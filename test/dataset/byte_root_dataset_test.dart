// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
//
import 'dart:io';

import 'package:core/server.dart' hide group;
import 'package:converter/converter.dart';
import 'package:test/test.dart';

String inRoot0 = 'C:/odw_test_data/sfd/CR';
String inRoot1 = 'C:/odw_test_data/sfd/CR_and_RF';
String inRoot2 = 'C:/odw_test_data/sfd/CT';
String inRoot3 = 'C:/odw_test_data/sfd/MG';
String inRoot4 = 'C:/odw_test_data/sfd/RTOG STUDY/RTOG STUDY/RTFiles-1';
String inRoot5 = 'C:/odw_test_data/mweb/TransferUIDs';

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';

void main() {
  Server.initialize(name: 'dataset/byte_root_dataset_dart', level: Level.info0);
  // Get the files in the directory
  final files = getFilesFromDirectory(inRoot5, '.dcm');
  stdout.writeln('File count: ${files.length}');

  // Read, parse, and print a summary of each file.
  group('Data set', () {
    test('Create a data set object from map', () {
      for (var file in files) {
        log.debug('Reading file: $file');
        ByteRootDataset rds;
        rds = ByteReader.readFile(file);
        if (rds == null) {
          log.debug('Error: Skipping ... $file');
          continue;
        }
        log.debug('File name ${file.path} with Transfer Syntax UID: '
            '${rds.fmi[0x00020010].value}');

        expect(() => rds.fmi[0x00020010], isNotNull);
        expect(() => rds.fmi[0x00020010].values, isNotNull);

        expect(() => rds[0x00020010], isNotNull);
        expect(() => rds[0x00020010].values, isNotNull);

        expect(() => rds[0x00143012], isNotNull);
        expect(() => rds[0x00143012].values, isNotNull);

        expect(() => rds[0x00143073], isNotNull);
        expect(() => rds[0x00143073].values, isNotNull);
        expect(() => rds[0x00143073].values.elementAt(0), isNotNull);

        expect(() => rds[0x00280008], isNotNull);
        expect(() => rds[0x00280008].values, isNotNull);

        log
          ..debug('         Pixel Data: '
              '${rds[0x7FE00010]?.values?.elementAt(0)}')
          ..debug('          Number of Frames: '
              '${rds[0x00280008]?.values?.elementAt(0)}')
          ..debug('          Number of frames integrated: '
              '${rds[0x00143012]?.values?.elementAt(0)}')
          ..debug('          Number of Frames Used for Integration: '
              '${rds[0x00143073]?.values?.elementAt(0)}');
      }
    });
  });
}
