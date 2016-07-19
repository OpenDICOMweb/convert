// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the   AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/server.dart';
import 'package:convert/convert.dart';
import 'package:odwsdk/dataset_sop.dart';
import 'package:odwsdk/system.dart';

String crf1 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.17895.5.dcm";
String crf2 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.48879.7.dcm";

void main() {
  System.logLevel = Level.config;
  Logger log = System.log;

  var path = crf1;

  File file = new File(path);
  log.info('Reading file: $file');
  DcmDecoder reader = new DcmDecoder.fromFile(file);

  Instance instance = reader.readSopInstance();
  Study study = instance.study;
  //print(study);
  Format fmt = new Format();
  var s = fmt.study(study);
  print(s);
}
