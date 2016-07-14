// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/server_logger.dart';
import 'package:convert/convert.dart';
import 'package:odwsdk/dataset_sop.dart';

var dirPath0 = 'D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/Group2_dcm4che';
var dirpath1 = 'D:/M2sata/mint_test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original';
var dirPath1 = 'D:/M2sata/mint_test_data/sfd/CT/20_phase/1_DICOM_Original';

void main() {
  ServerLogger server = new ServerLogger("main", Level.info);
  Logger log = new Logger("main", Level.warning);

  Directory dir = new Directory(dirPath1);

  List<FileSystemEntity> fList = dir.listSync();
  print('File count: ${fList.length}');
  for(File f in fList)
    print('File: $f');

  Study study;

 for(File f in fList) {
    DcmReader buf = new DcmReader.fromFile(f);
    study = buf.readSopInstance(study);
 }

  print('Study: ${study.series}');
  print('Study: ${study.instances}');
}
