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

import 'test_files.dart';

// ignore_for_file: avoid_catches_without_on_clauses

Future main() async {
  Server.initialize(
      name: 'ReadFile',
      level: Level.debug,
      throwOnError: false,
      minYear: 1901,
      maxYear: 2049,
      showBanner: true,
      showSdkBanner: false);

  final inPath = cleanPath(x1);

  final file =  File(inPath);
  final fLength = file.lengthSync();
  stdout
    ..writeln('Reading($fLength bytes): $inPath')
    ..writeln('Reading(binary): $inPath');

  RootDataset bdRds;
  try {
    bdRds = ByteReader.readPath(inPath, doLogging: true);
  } on InvalidTransferSyntax {
//    if (throwOnError)  rethrow;
    exit(-1);
  } on ShortFileError {
    log.error('Short file error');
//    if (throwOnError == true)  rethrow;
    exit(-1);
  } on RangeError catch(e){
    log.error(e);
 //   if (throwOnError == true)  rethrow;
    exit(-1);
  } catch (e) {
    log.error(e);
    if (throwOnError)
      rethrow;
  }
  final length = bdRds.lengthInBytes;
  print('File: $length bytes (${length ~/ 1024}K) read');
  print('RootDataset: ${bdRds.total} Elements');
  print(bdRds.summary);
  print('------');
  final tagRds = TagRootDataset.convert(bdRds);
  print(tagRds.format( Formatter.basic()));
  print('${tagRds.pcTags}');
}
