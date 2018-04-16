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


const List<String> files = const <String>[xx0, xx1, xx2, xx3, xxx];


void main() async {
  Server.initialize(name: 'ReadWriteFile', level: Level.debug, throwOnError:
  true);

  final inPath = cleanPath(xx3);

  log.info('path: $inPath');
  final length = new File(inPath).lengthSync();
  stdout.writeln('Reading($length bytes): $inPath');

  final rds = ByteReader.readPath(inPath, doLogging: true);
  if (rds == null) {
    log.warn('Invalid DICOM file: $inPath');
  } else {
    log.info('${rds.summary}');
  }

  final outPath = getVNAPath(rds, 'bin/output', 'dcm');
  final out = ByteWriter.writePath(rds, outPath);
  log
    ..info('outPath: $outPath')
    ..info('Output length: ${out.length}(${out.length ~/ 1024}K)')
    ..info('done');
}
