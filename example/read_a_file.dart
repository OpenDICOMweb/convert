// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/server_logger.dart';
import 'package:convert/convert.dart';
import 'package:odwsdk/dataset_sop.dart';

String crf1 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.17895.5.dcm";
String crf2 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.48879.7.dcm";

void main() {
  ServerLogger server = new ServerLogger("main", Level.info);
  Logger log = new Logger("main", Level.info);

  Study study;

  DcmReader buf = new DcmReader.fromFile(crf1);

  study = buf.readSopInstance(study);

  print('Study: $study');
}
