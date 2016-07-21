// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/server.dart';
import 'package:convert/convert.dart';
import 'package:odwsdk/dataset_sop.dart';
import 'package:odwsdk/uid.dart';

import 'package:odwsdk/system.dart';

var dirPath0 = 'D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/Group2_dcm4che';
var dirPath1 = 'D:/M2sata/mint_test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original';
var dirPath2 = 'D:/M2sata/mint_test_data/sfd/CT/20_phase/1_DICOM_Original';

void main() {
  Logger log = System.init(level: Level.info);

  Directory dir = new Directory(dirPath0);

  List<FileSystemEntity> fList = dir.listSync();
  log.info('File count: ${fList.length}');
  for (File f in fList)
    log.info('File: $f');

  Map<Uid, Study> studies = {};

  for (File f in fList) {
    var instance = readInstance(f);
    var study = instance.study;
    studies[study.uid] = study;
  }

  for (Study study in studies.values)
      printStudy(study);
}

void printStudy(Study study) =>
  print('Study(${study.uid}) with ${study.series.length} Series, '
            'and ${study.instances.length} Instances.');



Instance readInstance(File f) {
  var bytes = f.readAsBytesSync();
  DcmDecoder decoder = new DcmDecoder(bytes);
  return decoder.readSopInstance();
}
