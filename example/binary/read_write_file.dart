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
const String xx4 =
    'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

const List<String> files = const <String>[xx0, xx1, xx2, xx3, xx4];

void main() async {
  Server.initialize(
      name: 'ReadWriteFile', level: Level.debug, throwOnError: false);

  final inPath = cleanPath(xx4);

  log.info('path: $inPath');
  final length = new File(inPath).lengthSync();
  stdout.writeln('Reading($length bytes): $inPath');

  final rds0 = ByteReader.readPath(inPath, doLogging: true);
  if (rds0 == null) {
    log.warn('Invalid DICOM file: $inPath');
  } else {
    log.info('${rds0.summary}');
  }

  log.info('${rds0.dsBytes}');

  final outPath = getVNAPath(rds0, 'bin/output/', 'dcm');
  final outBytes = ByteWriter.writeBytes(rds0, doLogging: true);
  log
    ..up
    ..info('| Out Path: $outPath')
    ..info('| Output length: ${outBytes.length}(${outBytes.length ~/ 1024}K)')
    ..info('| ${outBytes.asUint8List(132, 32)}')
    ..info('| Done');

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
