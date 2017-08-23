// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:system/server.dart';
import 'package:dcm_convert/dcm.dart';

import 'package:dcm_convert/data/test_files.dart';

var pathx ='c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';
var pathy = 'C:/odw/test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original/'
    'EFC524F2.dcm';

//Urgent: bug with path20
Future main() async {
  Server.initialize(level: Level.debug2, throwOnError: true);

  var path = pathy;
  var url = new Uri.file(path);

  stdout.writeln('Reading(byte): $url');

  File file = new File(path);
//  Uint8List bytes = await readFileAsync(file);
  RootByteDataset rds = await ByteReader.readFile(file);
  if (rds == null) {
    log.warn('Invalid DICOM file: $path');
  } else {
    log.info0('${rds.parseInfo.info}');
    log.info0('Bytes Dataset: ${rds.summary}');
    Formatter z = new Formatter();
    print(format(rds.format(z)));
  }
}

Future<Uint8List> readFileAsync(File file) async {
  return await file.readAsBytes();

}