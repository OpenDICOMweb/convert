// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
//import 'package:dcm_convert/data/test_files.dart';
import 'package:convert/src/utilities/dicom_file_utils.dart';
import 'package:core/server.dart';

import 'package:convert/src/json/writer/dcm_writer2.dart';

const String k6684x0 =
    'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

const String k6684x1 =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug3, throwOnError: true);

  final fPath = k6684x0;

  log.info('path: $fPath');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final bytes = readPath(fPath);
  if (bytes == null) {
    log.error('"$fPath" either does not exist or is not a valid DICOM file');
    return;
  } else {
    stdout.writeln('  Length in bytes: ${bytes.lengthInBytes}');
  }

  final rds =
      BDReader.readBytes(bytes, path: fPath, doLogging: true, showStats: true);
  if (rds == null) {
    log.warn('Invalid DICOM file: $fPath');
  } else {
    log.info('${rds.summary}');
  }

  log.info(' out: ${getTempFile(fPath, 'dcmout')}');
  final outPath = 'out.json';
  final out =
      new FastJsonWriter(rds, outPath, separateBulkdata: true, tabSize: 2)
          .write();
  log.info('output length: ${out.length ~/ 1024}');
  new File(outPath).writeAsStringSync(out);
  log.info('done');
}


