// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:convert/src/utilities/io_utils.dart';

// ignore_for_file: only_throw_errors

const String k6684 = 'C:/acr/odw/test_data/6684';
const String k6688 = 'C:/acr/odw/test_data/6688';
const String dir6684_2017_5 = 'C:/acr/odw/test_data/6684/2017/5/12/16/0EE11F7A';

Future main() async {
  final  dir = new Directory(dir6684_2017_5);
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


