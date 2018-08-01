// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:converter/converter.dart';
import 'package:core/server.dart';

const String xx0 = 'C:/odw_test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)'
    '/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';
const String xx1 = 'C:/odw_test_data/mweb/ASPERA/DICOM files only'
    '/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm';
const String xx2 = 'C:/odw_test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.3.1.2.5.5.dcm';
const String xx3 =
    'C:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm';

Future main() async {
  Server.initialize(
      name: 'Read Binary write FastJson',
      level: Level.debug,
      throwOnError: true);

  final inPath = cleanPath(xx1);
  log.info('path: $inPath');
  stdout.writeln('Reading(byte): $inPath');

  final rds = ByteReader.readPath(inPath, doLogging: false);
  if (rds == null) {
    log.warn('Invalid DICOM file: $inPath');
  } else {
    log.info('${rds.summary}');
  }

  final study = rds.getUid(kStudyInstanceUID);
  final series = rds.getUid(kSeriesInstanceUID);
  final instance = rds.getUid(kSOPInstanceUID);
  final base = '$study-$series-$instance';
  final outPath =
      getOutputPath(inPath, dir: 'bin/output', base: base, ext: 'fjson');
  log.info('outPath: $outPath');
  final out =
      new FastJsonWriter(rds, outPath, separateBulkdata: true, tabSize: 2)
          .write();
  log.info('Output length: ${out.length}(${out.length ~/ 1024}K)');
  new File(outPath).writeAsStringSync(out);
  log.info('done');
}
