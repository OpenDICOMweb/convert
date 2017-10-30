// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/byte_convert.dart';
import 'package:path/path.dart' as path;
import 'package:system/server.dart';

const String pathx = 'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';
const String pathy = 'C:/odw/test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original/'
    'EFC524F2.dcm';
const String pathz = 'C:/odw/test_data/mweb/100 MB Studies/MRStudy/'
    '1.2.840.113619.2.5.1762583153.215519.978957063.99.dcm';

//Urgent: bug with path20
Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug2, throwOnError: true);
  system.level = Level.debug2;
  system.log.level = Level.debug2;

  final fPath = pathz;
  print('path: $fPath');
  print(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);

  stdout.writeln('Reading(byte): $url');

  final file = new File(fPath);
  final bytes = await readFileAsync(file);
  final rds = ByteReader.readBytes(bytes);
  if (rds == null) {
    log.warn('Invalid DICOM file: $fPath');
  } else {
    if (rds.parseInfo != null) {
      log..info0('${rds.parseInfo.info}')..info0('Bytes Dataset: ${rds.summary}');
      final z = new Formatter(maxDepth: -1);
      print(rds.format(z));
    } else {
      print('Error: $rds');
    }
  }
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}
