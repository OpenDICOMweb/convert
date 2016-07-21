// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/server.dart';
import 'package:convert/convert.dart';
import 'package:odwsdk/dataset_sop.dart';
import 'package:odwsdk/system.dart';

String crf1 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.17895.5.dcm";
String crf2 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.48879.7.dcm";

String outPath = 'output.dcm';

void main() {
  Logger log = System.init(level: Level.debug);
  var path = crf2;

  // Read a File
  File inFile = new File(path);
  log.info('Reading file: $inFile');
  var bytes = inFile.readAsBytesSync();
  print('length= ${bytes.length}');
  DcmDecoder decoder = new DcmDecoder(bytes);
  Instance instance = decoder.readSopInstance();
  Study study = instance.study;

  // Write a File
  log.level = Level.debug;
  File outFile = new File(outPath);
  log.info('Writing file: $outFile');
  DcmEncoder writer = new DcmEncoder(bytes.length + 1024);
  writer.writeSopInstance(instance);
  print('writeIndex: ${writer.writeIndex}');
  var outBytes = writer.bytes.buffer.asUint8List(0, writer.writeIndex);
  print('out length: ${bytes.length}');
  outFile.writeAsBytesSync(outBytes);

  //print(study);
  Format fmt = new Format();
  var s = fmt.study(study);
  print(s);
}