// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.

// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:logger/server.dart';
import 'package:convert/convert.dart';
import 'package:core/dataset_sop.dart';
import 'package:core/system.dart';

String testData = "C:/odw/sdk/convert/test_data/";
String testOutput = "C:/odw/sdk/convert/test_output/";

List pidMint10 = [
  "PID_MINT10", [
    "PID_MINT10/CR.2.16.840.1.114255.393386351.1568457295.17895.5.dcm",
    "PID_MINT10/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm"
  ]
];
String crf1 = "PID_MINT10/CR.2.16.840.1.114255.393386351.1568457295.17895.5.dcm";
String crf2 = "PID_MINT10/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm";


void main() {
  Logger log = System.init(level: Level.config);
  String inPath = testData + crf2;
  String outPath = testOutput + crf2;
  Format fmt;
  Study study;
  String fmtOutput;

  // Read a File
  File inFile = new File(inPath);
  log.info('Reading file: $inFile');
  Uint8List bytes = inFile.readAsBytesSync();
  print('length= ${bytes.length}');

  DcmDecoder decoder = new DcmDecoder(bytes);
  Instance instance = decoder.readSopInstance();
  study = instance.study;
  //print(study);
  //fmt = new Format();
  //fmtOutput = fmt.study(study);
  // print(fmtOutput);

  // Write a File
  log.level = Level.config;
  File outFile = new File(outPath);
  log.info('Writing file: $outFile');

  DcmEncoder writer = new DcmEncoder(bytes.length + 1024);
  writer.writeSopInstance(instance);
  print('writeIndex: ${writer.writeIndex}');

  var outBytes = writer.bytes.buffer.asUint8List(0, writer.writeIndex);
  print('out length: ${bytes.length}');
  outFile.writeAsBytesSync(outBytes);

  //print(study);
  fmt = new Format();
  fmtOutput = fmt.study(study);
  print(fmtOutput);
}