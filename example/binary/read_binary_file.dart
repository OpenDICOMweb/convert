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

const String mweb0 = 'C:/odw/test_data/mweb/1000+/DIASTOLIX/DIASTOLIX/'
    'CorCTALow  2.0  B25f 0-95%/IM-0004-0001.dcm';

const String mweb1 = 'C:/odw/test_data/mweb/1000+/DIASTOLIX/DIASTOLIX/'
    'CorCTALow  2.0  B25f 0-95%/IM-0004-0001.dcm';
///
Future main() async {
  Server.initialize(
      name: 'ReadFile',
      level: Level.debug,
      throwOnError: true,
      minYear: 1901,
      maxYear: 2049,
      showBanner: true,
      showSdkBanner: true);

  final inPath = cleanPath(mweb1);
  final fLength = new File(inPath).lengthSync();
  stdout
    ..writeln('Reading($fLength bytes): $inPath')
    ..writeln('Reading(binary): $inPath');

  final rds = ByteReader.readPath(inPath, doLogging: true);

  final length = rds.lengthInBytes;
  print('File: $length bytes (${length ~/ 1024}K) read');
  print('RootDataset: ${rds.total} Elements');
}
