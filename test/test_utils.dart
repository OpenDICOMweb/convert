//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:io';

import 'package:core/server.dart' hide group;
import 'package:converter/src/binary/byte/reader/byte_reader.dart';

int filesRead = 1;

RootDataset readPath(String inPath, {bool doLogging = true}) {
  final path = cleanPath(inPath);
  log.debug('path: $path');
  final length = File(path).lengthSync();
  if (doLogging) stdout.writeln('$filesRead: Reading($length bytes): $path');
  final rds =  ByteReader.readPath(path, doLogging: doLogging);
  filesRead++;
  return rds;
}

/// [doShortTest] controls the number of files tested.
const bool doShortTest = true;
int fileCount;

const String dir6684 = 'C:/odw_test_data/6684/2017/5/13/0/0B5106EF/';
const String dirMECANIX = 'C:/odw_test_data/mweb/500+/MECANIX/';
const String dirMweb = 'C:/odw_test_data/mweb/';

List<String> listFile() {
  const x0 = doShortTest ? dirMweb : 'C:/odw_test_data/';
  print('Directory: $x0');
  final dir = Directory(x0);
  final fList = dir.listSync(recursive: true);
  final fsEntityCount = fList.length;

  log.debug('FSEntity count: $fsEntityCount');

  //final files = <File>[];
  final files = <String>[];
  for (var fse in fList) {
    if (fse is File) {
      final path = fse.path;
      // Urgent Sharath: this should handle files with no extension
      // i.e. foo or foo.dir
      if (path.contains('.')) {
        if (path.endsWith('.dcm')) files.add(path);
      } else {
        files.add(path);
      }
    }
  }
  fileCount = files.length;
  return files;
}