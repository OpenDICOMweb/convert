//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';

import 'package:convert/data/test_files.dart';
///
void main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug, throwOnError: true);

  final inPath = cleanPath(k6684x0);
  log.info('path: $inPath');
  final length = new File(inPath).lengthSync();
  stdout.writeln('Reading($length bytes): $inPath');

  final rds = ByteReader.readPath(inPath, doLogging: true);
  if (rds == null) {
    log.warn('Invalid DICOM file: $inPath');
  } else {
    log.info('${rds.summary}');
  }

  final outPath = getVNAPath(rds, 'bin/output', 'dcm');
  final out = ByteWriter.writePath(rds, outPath);
  log
    ..info('outPath: $outPath')
    ..info('Output length: ${out.length}(${out.length ~/ 1024}K)')
    ..info('done');
}
