// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.convert.dcm.compare_files;

import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

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

    for(int i = 0; i < min; i++) {
      if (bytes0[i] != bytes1[i]) {
        print('Difference at position $i');
        print('  bytes0 = ${bytes0[i]}');
        print('  bytes1 = ${bytes1[i]}');
        return "Files are different";
      }
    }
    return "Files are the same.";
  }

}