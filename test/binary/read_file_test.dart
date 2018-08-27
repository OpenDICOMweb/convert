//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:io';

import 'package:converter/converter.dart';
import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

const String path0 = 'C:/odw_test_data/mweb/TransferUIDs'
    '/1.2.840.10008.1.2.5.dcm';

void main() {
  Server.initialize(
      name: 'ByteReader Test', throwOnError: true, level: Level.info);

  test('ByteReader Read file', () {
    final rds = ByteReader.readPath(path0);
    log.debug('${rds.info}');
    final entity = activeStudies.entityFromRootDataset(rds);
    log.debug('${entity.info}');
  });

  test('read_files', () {
    global.level = Level.debug;
    final files = listFile();
    for (var i = 0; i < files.length; i++) {
      final inPath = cleanPath(files[i]);

      log.debug('path: $inPath');
      final length = new File(inPath).lengthSync();
      stdout.writeln('Reading($length bytes): $inPath');

      final rds0 = ByteReader.readPath(inPath, doLogging: true);
      if (rds0 == null) {
        log.warn('Invalid DICOM file: $inPath');
      } else {
        log.debug('rds0.summary: ${rds0.summary}');
        expect(rds0.isNotEmpty, true);
        //expect(rds0.elements.length != 0, true);
        expect(rds0.duplicates, <int>[]);
        expect(rds0.nPrivateElements != 0, true);
        expect(rds0.lengthInBytes == rds0.dsBytes.vfLength, true);
        expect(rds0.prefix == rds0.dsBytes.prefix, true);
        expect(rds0.preamble == rds0.dsBytes.preamble, true);
        expect(rds0.isEvr == rds0.transferSyntax.isEvr, true);
        expect(rds0.isIVR == rds0.transferSyntax.isIvr, true);
        expect(rds0.duplicates == rds0.history.duplicates, true);
        expect(rds0.pixelRepresentation >= 0, true);
        expect(rds0.samplesPerPixel >= 1, true);
        expect(rds0.photometricInterpretation, isNotNull);
        expect(rds0.rows, isNotNull);
        expect(rds0.columns, isNotNull);
        expect(rds0.bitsAllocated, isNotNull);
        expect(rds0.bitsStored, isNotNull);
        expect(rds0.highBit, isNotNull);
      }

      log.debug('rds0.dsBytes: ${rds0.dsBytes}');
    }
  });

  test('read_write_read files', () {
    final files = listFile();
    for (var i = 0; i < files.length; i++) {
      final inPath = cleanPath(files[i]);
      log.info('$i path: $inPath');
      final length = new File(inPath).lengthSync();
      stdout.writeln('Reading($length bytes): $inPath');

      final rds0 = ByteReader.readPath(inPath, doLogging: false);
      if (rds0 == null) {
        log.warn('Invalid DICOM file: $inPath');
      } else {
        log.info('${rds0.summary}');
      }

      log.info('${rds0.dsBytes}');

      final outPath = getVNAPath(rds0, 'bin/output/', 'dcm');
      final outBytes = ByteWriter.writeBytes(rds0, doLogging: false);
      log
        ..info('outPath: $outPath')
        ..info('Output length: ${outBytes.length}(${outBytes.length ~/ 1024}K)')
        ..info('done');

      expect(outBytes.isNotEmpty, true);
      expect(outBytes.limit == outBytes.length, true);
      expect(
          outBytes.buffer.lengthInBytes == outBytes.asByteData().lengthInBytes,
          true);
      expect(outBytes.asUint8List(), equals(outBytes.buffer.asUint8List()));
      expect(outBytes.elementSizeInBytes == 1, true);
      expect(outBytes.offset == outBytes.asByteData().offsetInBytes, true);
      expect(outBytes.vrIndex == vrIndexByCode8Bit[outBytes.vrCode], true);
      expect(outBytes.asInt8List(), equals(outBytes.buffer.asInt8List()));

      final rds1 = ByteReader.readBytes(outBytes, doLogging: false);
      if (rds1 == null) {
        log.warn('Invalid DICOM file: $outPath');
      } else {
        log.info('${rds1.summary}');
      }

      final result = (rds0 == rds1) ? 'Success' : 'Failure';
      print(result);

      if (result == 'Success')
        expect(rds0 == rds1, true);
      else
        expect(rds0 == rds1, false);
    }
  });
}

List<String> listFile() {
  const x0 = 'C:/odw/test_data/mweb/500+/';
  int fsEntityCount;
  final dir = new Directory(x0);

  final fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  //final files = <File>[];
  final files = <String>[];
  for (var fse in fList) {
    if (fse is File) {
      final path = fse.path;
      if (path.endsWith('.dcm')) {
        files.add(path);
      }
    }
  }
  return files;
}
