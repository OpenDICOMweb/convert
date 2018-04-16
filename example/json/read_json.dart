//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';
import 'package:io/io.dart';

//import 'package:convert/data/test_files.dart';

const String k6684x0 = 'C:/acr/odw/sdk/convert/bin/output/'
    '1.2.840.113745.101000.1061000.41090.4218.18582671-'
    '1.3.46.670589.11.21290.5.0.6524.2012072512045421001-'
    '1.3.46.670589.11.21290.5.0.6524.2012072512045712193.json';

void main() {
  Server.initialize(
      name: 'ReadJsonFile', level: Level.debug3, throwOnError: true);

  final inPath = cleanPath(k6684x0);
  log.info('path: $inPath');
  stdout.writeln('Reading(byte): $inPath');

  final rds = JsonReader.fromPath(inPath);
  if (rds == null) {
    log.error('"$inPath" either does not exist or is not a valid DICOM file');
    return;
  } else {
    log.info('${rds.summary}');
  }

  final outPath = getOutputPath(k6684x0, dir: 'bin/output', ext: 'json');

  print('RDS length: ${rds.length ~/ 1024}');
  print('RDS: ${rds.info}');
  print('outPath: $outPath');
  print('done');
}


