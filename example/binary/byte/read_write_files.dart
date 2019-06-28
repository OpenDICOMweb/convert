//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:async';
import 'dart:io';

import 'package:converter/converter.dart';
import 'package:core/server.dart';

import '../test_files.dart';

Future<void> main() async {
  Server.initialize(
      name: 'ReadWriteFiles', level: Level.debug, throwOnError: false);

  for (var i = 0; i < files.length; i++) {
    final inPath = cleanPath(files[i]);
    log.info('$i path: $inPath');
    final length =  File(inPath).lengthSync();
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

    final rds1 = ByteReader.readBytes(outBytes, doLogging: false);
    if (rds1 == null) {
      log.warn('Invalid DICOM file: $outPath');
    } else {
      log.info('${rds1.summary}');
    }

    final result = (rds0 == rds1) ? 'Success' : 'Failure';
    print(result);
  }
}
