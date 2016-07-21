// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.convert.dcm.compare_files;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'package:ascii/ascii.dart';

//TODO:
// 1. create log of differences
// 2. Create a method that slides forward to find the next position where things are equal.
// 3. Consider creating a class that compares two Studies in memory.

/// Compares the bytes in two files to determine if they are the same.
class FileCompare {
  String path0;
  String path1;
  String output = "";
  bool exitOnError;

  FileCompare(this.path0, this.path1, {this.exitOnError: false});

  String get compare {
    //TODO:
    //System.logLevel = Level.config;
    //Logger log = System.log;
    String normal0 = path.normalize(path0);
    String normal1 = path.normalize(path1);

    print('Comparing:\n  $normal0, and\n  $normal1');

    File file0 = new File(path0);
    File file1 = new File(path1);
    //log.info('Compare files: $path0 and $path1');

    Uint8List bytes0 = file0.readAsBytesSync();
    Uint8List bytes1 = file1.readAsBytesSync();

    var length0 = bytes0.length;
    var length1 = bytes1.length;
    print('bytes0.length: ${bytes0.length}');
    print('bytes1.length: ${bytes1.length}');

    if (length0 != length1) {
      print('Unequal Length Error');
      if (exitOnError) exit(255);
    }

    int min = (length0 < length1) ? length0 : length1;

    var maxCount = 3;
    var status = "the same.";
    var count = 0;

    for(int i = 0; i < min; i++) {
      if (bytes0[i] != bytes1[i]) {
        if(count++ > maxCount) exit(255);
        print('Difference at position $i');
        print('  bytes0[$i] = ${bytes0[i]}');
        print('  bytes1[$i] = ${bytes1[i]}');
        print('  bytes0: ${bytes0.sublist(i-8, i+20)}');
        print('  bytes1: ${bytes1.sublist(i-8, i+20)}');
        print('  bytes0: ${toAscii(bytes0.sublist(i-8, i+20))}');
        print('  bytes1: ${toAscii(bytes1.sublist(i-8, i+20))}');
        status = "different.";
      }
    }
    return "Files are $status";
  }

}

List<String> toAscii(List<int> list) {
  var cList = new List<String>(list.length);
  for (int i = 0; i < list.length; i++) {
    int c = list[i];
    var v = (Ascii.isVisibleChar(c)) ? new String.fromCharCode(c) : c.toString();
    cList[i] = v;
  }
  return cList;
}