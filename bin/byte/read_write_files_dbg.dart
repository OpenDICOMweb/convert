// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'package:system/core.dart';

import 'package:dcm_convert/data/test_files.dart';
import 'package:system/server.dart';

import 'package:dcm_convert/src/tool/do_rwr_byte_file.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

const String foo = 'C:/odw/test_data/mweb/ASPERA/DICOM files only/22f01f4d-32c0-4a13-9350-9f0b4390889b.dcm';
const String ivrNoSequences = 'C:/odw/test_data/mweb/100 MB Studies/MRStudy'
		'/1.2.840.113619.2.5.1762583153.215519.978957063.101.dcm';

const String bar = 'C:/odw/test_data/mweb/10 Patient IDs/04443352';

void main() {
  Server.initialize(name: 'read_write_file', level: Level.debug3);

  system.throwOnError = true;
  // *** Modify [paths] value to read/write a different file
  final paths = testEvrPaths;
  //paths.addAll(testPaths0);
 // paths.addAll(testPaths1);
 // paths.addAll(testPaths2);
//  ..addAll(testErrors);

  for (var i = 0; i < 1; i++) {
  	final f = new File(paths[19]);
  	stderr.writeln('$f');
  	log.info('$i Start RW File: $f');
    doRWRByteFile(f);
	  log.info('$i End RW File: $f');
  }
}

