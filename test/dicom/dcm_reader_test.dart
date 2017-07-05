// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/dicom/dcm_reader.dart';
import 'package:test/test.dart';

void main() {
  String path0 =
      'C:/odw/sdk/test_tools/test_data/TransferUIDs/1.2.840.10008.1.2.5.dcm';
  final Logger log = new Logger('dcm_reader_test.dart', watermark: Severity
      .debug);
  group('description', () {

    test("instance ", () {
  //    Uid uid = new Uid();
      File script = new File(path0);
      var bytes = script.readAsBytesSync();

      Dataset rds = DcmReader.rootDataset(bytes, path0);
      log.debug('${rds.info}');
      //    Subject subject = new Subject(rds);
      //    Study stu = new Study(subject, uid, rds);
      //    Series ser = new Series(stu, uid, rds);
      //    Instance inst = new Instance(ser, uid, rds);
      //    Instance inst1 = new Instance(ser, uid, rds);
      Instance instance = new Instance.fromDataset(rds);
      log.debug('${instance.info}');
 //     expect(inst == inst1, true);
 //     expect(inst.hashCode == inst1.hashCode, true);
    });
    
  });

}