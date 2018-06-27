//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:core/server.dart';
import 'package:io/io.dart';


import 'test_files.dart';

const List<String> files = const <String>[x0, x1, x2, x3, x4];

void main() async {
  Server.initialize(
      name: 'ReadWriteFile', level: Level.debug, throwOnError: false);

  final inPath = cleanPath(x4);

  log.info('path: $inPath');
  final length = new File(inPath).lengthSync();
  stdout.writeln('Reading($length bytes): $inPath');

  final rds0 = ByteReader.readPath(inPath, doLogging: true);
  if (rds0 == null) {
    log.warn('Invalid DICOM file: $inPath');
  } else {
    log.info('${rds0.summary}');
  }

  log.info('${rds0.dsBytes}');

  final outPath = getVNAPath(rds0, 'bin/output/', 'dcm');
  final outBytes = ByteWriter.writeBytes(rds0, doLogging: true);
  log
    ..up
    ..info('| Out Path: $outPath')
    ..info('| Output length: ${outBytes.length}(${outBytes.length ~/ 1024}K)')
    ..info('| ${outBytes.asUint8List(132, 32)}')
    ..info('| Done');

  outBytes.endian = Endian.little;
  final rds1 = ByteReader.readBytes(outBytes, doLogging: true);
  if (rds1 == null) {
    log.warn('Invalid DICOM file: $outPath');
  } else {
    log.info('${rds1.summary}');
  }

  final result = (rds0 == rds1) ? 'Success' : 'Failure';
  print(result);
}
