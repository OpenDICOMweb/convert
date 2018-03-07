// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';

import 'package:convert/data/test_files.dart';
///
Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.info, throwOnError: true);

  final inPath = cleanPath(k6684x0);
  stdout.writeln('Reading(binary): $inPath');

  final rds = BDReader.readPath(inPath, doLogging: false, showStats: true);

  final length = rds.bd.lengthInBytes;
  print('File: $length bytes (${length ~/ 1024}K) read');
  print('RootDataset: ${rds.total} Elements');
}
