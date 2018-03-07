// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/src/utilities/io_utils.dart';

// ignore_for_file: only_throw_errors

const String k6684 = 'C:/acr/odw/test_data/6684';
const String k6688 = 'C:/acr/odw/test_data/6688';
const String dir6684_2017_5 = 'C:/acr/odw/test_data/6684/2017/5/12/16/0EE11F7A';


void main() {
  final  dir = new Directory(dir6684_2017_5);
  final  stat = dir.statSync();
  final  length = dir.listSync(recursive: true).length;
  print(stat);
  print('length: $length');

//  final path = cleanPath(dir.path);
//  print('Walking $path...');
  indenter = new Printer();

  final count = walkDirectorySync(dir, printIt);
  print('Total: $count');
  print('... Done');
}

Printer indenter;

void printIt(FileSystemEntity e, [int depth = 0]) {
  final  p = cleanPath(e.path);
  String s;
  if (e is File) {
    s = 'F: $p';
  } else if (e is Link) {
    s = 'L: $p';
  } else if (e is Directory) {
    s = 'D: Walking $p...';
  } else {
    s = 'Unknown';
  }
 // indenter.show(s, depth);

  final  spaces = ''.padRight(depth * 2);
  print('$spaces$s');
}

class Printer {
  final int width;

  Printer([this.width = 2]);

  String spaces(int depth) => ''.padRight(depth * width);

  void show(String s, int depth) => print('${spaces(depth)}$s');
}

class Indenter {
  final int width;
  StringBuffer _sb;

  Indenter([this.width = 2]);

  StringBuffer get sb => _sb ??= new StringBuffer();

  String spaces(int depth) => ''.padRight(depth * width);

  void write(String s, int depth) => sb.write(s);
  void writeln(String s, int depth) => sb.writeln('${spaces(depth)}$s');
}


