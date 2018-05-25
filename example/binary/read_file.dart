//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';
import 'package:io/io.dart';

// Explicit VR Little Endian
const String xx0 = 'C:/acr/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.3.1.2.5.5.dcm';

// Explicit VR JPEG 2000
const String xx1 =
    'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

// Implicit VR
const String xx2 = 'C:/acr/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)'
    '/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';

// Explicit VR Big Endian
const String xx3 =
    'C:/acr/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm';

// Explicit VR Big Endian
const String xx4 = 'C:/acr/odw/test_data/mweb/ASPERA/DICOM files only'
    '/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm';

// Explicit VR Little Endian with Private Tag codes and group length
const String xx5 =
    'C:/acr/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';

const String xx6 =
    'C:/acr/odw/test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original/EFC524F2.dcm';

// ignore_for_file: avoid_catches_without_on_clauses

Future main() async {
  Server.initialize(
      name: 'ReadFile',
      level: Level.debug,
      throwOnError: true,
      minYear: 1901,
      maxYear: 2049,
      showBanner: true,
      showSdkBanner: false);

  final inPath = cleanPath(xx6);

  final file = new File(inPath);
  final fLength = file.lengthSync();
  stdout
    ..writeln('Reading($fLength bytes): $inPath')
    ..writeln('Reading(binary): $inPath');

  RootDataset rds;
  try {
    rds = ByteReader.readPath(inPath, doLogging: true);
  } on InvalidTransferSyntax {
//    if (throwOnError)  rethrow;
    exit(-1);
  } on ShortFileError {
    log.error('Short file error');
//    if (throwOnError == true)  rethrow;
    exit(-1);
  } on RangeError catch (e) {
    log.error(e);
    //   if (throwOnError == true)  rethrow;
    exit(-1);
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
  }
  final length = rds.lengthInBytes;
  print('File: $length bytes (${length ~/ 1024}K) read');
  print('RootDataset: ${rds.total} Elements');
}
