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

String bug1 = 'C:/odw/sdk/odwsdk/dcm_files/IM-0001-0002.dcm';

String output = "output.dcm";

void main() {
  Logger log = System.init(level: Level.debug);
  var path = bug1;;

  File file = new File(path);
  log.info('Reading file: $file');
  var bytes = file.readAsBytesSync();
  DcmDecoder decoder = new DcmDecoder(bytes);
  print('decoder: $decoder');

  Instance instance = decoder.readSopInstance(path);
  print('main:instance: $instance');
  Study study = instance.study;
  print('main:study: $study');
  Format fmt = new Format();
  var s = fmt.study(study);
  print(s);
}
