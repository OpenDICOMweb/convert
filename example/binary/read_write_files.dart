//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:core/server.dart';
import 'package:io/io.dart';

const String xx3 =
    'C:/acr/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm';
const String xx2 = 'C:/acr/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.3.1.2.5.5.dcm';
const String xx1 = 'C:/acr/odw/test_data/mweb/ASPERA/DICOM files only'
    '/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm';
const String xx0 = 'C:/acr/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)'
    '/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';
const String xxx =
    'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';
const String dcmDir = 'C:/acr/odw/test_data/sfd/MG/DICOMDIR';
const String evrLarge =
    'C:/acr/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String evrULength =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';
const String evrX = 'C:/acr/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
    '/1.2.840.10008.5.1.4.1.1.88.67.dcm ';
// Defined and Undefined datasets
const String evrXLarge =
    'C:/acr/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';
const String evrOWPixels = 'C:/acr/odw/test_data/IM-0001-0001.dcm';

const String ivrClean =
    'C:/acr/odw/test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original/'
    'EFC524F2.dcm';
const String ivrCleanMR = 'C:/acr/odw/test_data/mweb/100 MB Studies/MRStudy/'
    '1.2.840.113619.2.5.1762583153.215519.978957063.99.dcm';

const String evrDataAfterPixels =
    'C:/acr/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';

const String ivrWithGroupLengths =
    'C:/acr/odw/test_data/mweb/100 MB Studies/MRStudy'
    '/1.2.840.113619.2.5.1762583153.215519.978957063.101.dcm';

const String bar = 'C:/acr/odw/test_data/mweb/10 Patient IDs/04443352';

const List<String> files = const <String>[
  xx0,
  xx1,
  xx2,
  xx3,
  xxx,
  dcmDir,
  evrLarge,
  evrX,
  evrXLarge,
  evrOWPixels,
  ivrClean,
  ivrCleanMR,
  evrDataAfterPixels,
  ivrWithGroupLengths,
  bar
];

void main() async {
  Server.initialize(
      name: 'ReadWriteFiles', level: Level.debug1, throwOnError: false);

  for (var i = 0; i < files.length; i++) {
    final inPath = cleanPath(files[i]);
    log.info('$i path: $inPath');
    final length = new File(inPath).lengthSync();
    stdout.writeln('Reading($length bytes): $inPath');

    final rds0 = ByteReader.readPath(inPath, doLogging: false);
    if (rds0 == null) {
      log.warn('Invalid DICOM file: $inPath');
    } else {
      log.info('${rds0.summary}');
    }

    log.info('${rds0.dsBytes}');

    final outPath = getVNAPath(rds0, 'bin/output/', 'dcm');
    final outBytes = ByteWriter.writeBytes(rds0, doLogging: true);
    log
      ..info('outPath: $outPath')
      ..info('Output length: ${outBytes.length}(${outBytes.length ~/ 1024}K)')
      ..info('done');

    outBytes.endian = Endian.little;
    final rds1 = ByteReader.readBytes(outBytes, doLogging: true);
    if (rds1 == null) {
      log.warn('Invalid DICOM file: $outPath');
    } else {
      log.info('${rds1.summary}');
    }

    final result = (rds0 == rds1) ? 'Success' : 'Failure';
    print(result);
  }
}
