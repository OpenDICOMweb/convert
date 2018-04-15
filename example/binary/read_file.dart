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

import 'package:convert/data/test_files.dart';

// ignore_for_file: avoid_catches_without_on_clauses

const List<String> path = testPaths1;

const String mweb0 = 'C:/odw/test_data/mweb/1000+/DIASTOLIX/DIASTOLIX/'
    'CorCTALow  2.0  B25f 0-95%/IM-0004-0001.dcm';
const String mweb1 = 'C:/odw/test_data/mweb/ASPERA/DICOM files only/'
    '22c82bd4-6926-46e1-b055-c6b788388014.dcm';
const String mweb2 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/'
    'Anonymized1.2.840.10008.3.1.2.5.5.dcm';
const String mweb3 = 'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/'
    '1_DICOM_Original/IM000003.dcm';
const String mweb4 = 'C:/odw/test_data/sfd/MG/Patient_38/'
    '1_DICOM_Original/IM000001.dcm';
const String mweb5 = 'C:/odw/test_data/mweb/100 MB Studies/Brain026/'
    'ST000000/SE000000/IM000000' ;
const String mweb6 = 'C:/odw/test_data/sfd/CT/Patient_3_Cardiac_CTA/'
    '1_DICOM_Original/IM000001.dcm';
const String mweb7 = 'C:/odw/test_data/mweb/ASPERA/DICOM files only/'
    '22c82bd4-6926-46e1-b055-c6b788388014.dcm';
const String mweb8 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/'
    'Anonymized.dcm';
const String mweb9 = 'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/'
    '1_DICOM_Original/IM000003.dcm';
const String mweb10 = 'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/'
    '1_DICOM_Original/IM000001.dcm';
const String mweb11 = 'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/'
    '1_DICOM_Original/IM000004.dcm';
const String mweb12 = 'C:/odw/test_data/sfd/CT/Patient_16_CT_Maxillofacial_'
    '-_Wegners/1_DICOM_Original/IM000004.dcm';
const String mweb13 = 'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/'
    'CT.2.16.840.1.114255.390617858.1794098916.10199.38535.dcm';
const String mweb14 = 'C:/odw/test_data/sfd/MG/Patient_38/1_DICOM_Original/'
    'IM000001.dcm';
const String mweb15 = 'C:/acr/odw/test_data/sfd/MG/Patient_41/1_DICOM_Original/'
    'IM000001.dcm';
const String mweb16 = '';
const String mweb17 = '';




///
Future main() async {
  Server.initialize(
      name: 'ReadFile',
      level: Level.debug,
      throwOnError: true,
      minYear: 1901,
      maxYear: 2049,
      showBanner: true,
      showSdkBanner: false);

  final inPath = cleanPath(mweb14);
  final file = new File(inPath);
  final fLength = file.lengthSync();
  stdout
    ..writeln('Reading($fLength bytes): $inPath')
    ..writeln('Reading(binary): $inPath');

  RootDataset rds;
  final toe = throwOnError;
  try {
    rds = ByteReader.readPath(inPath, doLogging: true);
  } on InvalidTransferSyntax {
    (toe) ? rethrow : exit(-1);
  } on ShortFileError {
    log.error('Short file error');
    (toe) ? rethrow : exit(-1);
  } on RangeError catch(e){
    log.error(e);
    (toe) ? rethrow : exit(-1);
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
  }
  final length = rds.lengthInBytes;
  print('File: $length bytes (${length ~/ 1024}K) read');
  print('RootDataset: ${rds.total} Elements');
}
