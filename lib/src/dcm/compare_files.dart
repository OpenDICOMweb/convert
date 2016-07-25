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

    Uint8List aIn = file0.readAsBytesSync();
    Uint8List bIn = file1.readAsBytesSync();

    var length0 = aIn.length;
    var length1 = bIn.length;
    print('A length: ${aIn.length}');
    print('B length: ${bIn.length}');

    if (length0 != length1) {
      print('Unequal Length Error');
      if (exitOnError) exit(255);
    }

    int min = (length0 < length1) ? length0 : length1;

    var maxCount = 3;
    var status = "the same.";
    var count = 0;

    int pre = 16;
    int post = 24;

    for(int i = 0; i < min; i++) {
      if (aIn[i] != bIn[i]) {
        if(count++ > maxCount) exit(255);
        print('aIn[$i] = ${aIn[i].toRadixString(16)}');
        print('bIn[$i] = ${bIn[i].toRadixString(16)}');
        printIt(aIn, bIn, i - pre, i + post, i);
        status = "different.";
      }
    }
    return "Files are $status";
  }

}



void printIt(List<int> aIn, List<int> bIn, int start, int end, int index) {
  /*
  length = (aIn.length > bIn.length) ? bIn.length : aIn.length;

  start = index - pre;
  if (start < 0) {
    index = index - start;
    start = 0;
  }
  end = index + post;
  if (end >= length) end = length;
  */
 print('start: $start, end: $end:  index: $index');
  String mark = "";
  mark += "".padRight((index - start) * 4, "-");
  mark += "++--";
  mark += "".padRight(((end - index) - 2) * 4, "-");
  print('      $mark');

  List<String> aOut = new List<String>(end - start);
  List<String> bOut = new List<String>(end - start);

  for (int i = start, j = 0; i < end; i++, j++) {
    //print('i: $i, j: $j');
    aOut[j] = aIn[i].toRadixString(16).padLeft(2, " ");
    bOut[j] = bIn[i].toRadixString(16).padLeft(2, " ");
  }

  print('  A: $aOut');
  print('  B: $bOut');

  for (int i = start, j = 0; i < end ; i++, j++) {
    aOut[j] = (Ascii.isVisibleChar(aIn[i]))
              ? new String.fromCharCode(aIn[i]).padLeft(2, " ") : " *";
    bOut[j] = (Ascii.isVisibleChar(bIn[i]))
              ? new String.fromCharCode(bIn[i]).padLeft(2, " ") : " *";
  }
  print('  A: $aOut');
  print('  B: $bOut');

}

void toAscii(List<int> aIn, List<int> bIn) {
  var aOut = new List<String>(aIn.length);
  var bOut = new List<String>(bIn.length);
  for (int i = 0; i < aIn.length; i++) {
    int a = aIn[i];
    int b = bIn[i];
    aOut[i] = (Ascii.isVisibleChar(a)) ? new String.fromCharCode(a) : "*";
    bOut[i] = (Ascii.isVisibleChar(b)) ? new String.fromCharCode(b) : "*";
  }
  print('  A:  ');
  print('  B:  ');
}