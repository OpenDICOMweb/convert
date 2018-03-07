// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';

import 'package:convert/data/test_files.dart';
///
void main() async {
  Server.initialize(name: 'ReadFile', level: Level.info, throwOnError: true);

  final inPath = cleanPath(k6684x0);
  log.info('path: $inPath');
  stdout.writeln('Reading(byte): $inPath');

  final rds = BDReader.readPath(inPath, doLogging: false, showStats: true);
  if (rds == null) {
    log.warn('Invalid DICOM file: $inPath');
  } else {
    log.info('${rds.summary}');
  }

  final outPath = getVNAPath(rds, 'bin/output', 'dcm');
  final out = BDWriter.writePath(rds, outPath);
  log
    ..info('outPath: $outPath')
    ..info('Output length: ${out.length}(${out.length ~/ 1024}K)')
    ..info('done');
}
