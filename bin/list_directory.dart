// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:convert/src/utilities/io_utils.dart';

Future main() async {
  final  dir = new Directory('C:/odw/test_data');
  final  stat = await dir.stat();
  final  length = dir.listSync(recursive: true).length;
  print(stat);
  print('length: $length');

  print('Walking ${dir.path}...');
  await walkDirectory(dir, printIt);
  print('... Done');
}

void printIt(FileSystemEntity e, [int level = 0]) {
  String type;
  if (e is File) {
    type = 'F';
  } else if (e is Link) {
    type = 'L';
  } else if (e is Directory) {
    throw 'This should never happen $e';
  } else {
    type = 'Unknown';
  }

  final  p = cleanPath(e.path);
  final  spaces = ''.padRight(level * 2);
  print('$level $spaces $type: $p');
}


