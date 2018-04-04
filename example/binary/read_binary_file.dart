// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';

import 'package:convert/data/test_files.dart';

const String mweb0 = 'C:/odw/test_data/mweb/1000+/DIASTOLIX/DIASTOLIX/'
    'CorCTALow  2.0  B25f 0-95%/IM-0004-0001.dcm';

//
const String mweb1 = 'C:/odw/test_data/mweb/ASPERA/DICOM files only/'
    '22c82bd4-6926-46e1-b055-c6b788388014.dcm';
const String mweb2 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/'
    'Anonymized1.2.840.10008.3.1.2.5.5.dcm';
const String mweb3 = 'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/'
    '1_DICOM_Original/IM000003.dcm';
const String mweb4 = 'C:/odw/test_data/sfd/MG/Patient_38/'
    '1_DICOM_Original/IM000001.dcm';

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

  final inPath = cleanPath(mweb3);
  final file = new File(inPath);
  final fLength = file.lengthSync();
  stdout
    ..writeln('Reading($fLength bytes): $inPath')
    ..writeln('Reading(binary): $inPath');

  RootDataset rds;
  try {
    rds = ByteReader.readPath(inPath, doLogging: true);
  } on InvalidTransferSyntax {
    exit(-1);
  } on ShortFileError {
    log.error('Short file error');
    exit(-1);
  } on RangeError catch(e){
    log.error(e);
    exit(-1);
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
  }
  final length = rds.lengthInBytes;
  print('File: $length bytes (${length ~/ 1024}K) read');
  print('RootDataset: ${rds.total} Elements');
}
