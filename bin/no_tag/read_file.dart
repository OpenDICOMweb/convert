// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';

import 'bad_files0.dart';
import 'package:convertX/dicom_no_tag.dart';
import '../../benchmark/test_files.dart';

const String testData = "C:/odw/test_data";
const String test6688 = "C:/odw/test_data/6688";
const String mWeb = "C:/odw/test_data/mweb";
const String mrStudy = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";
const String dir6688 = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D';

const String ivrFile = 'C:/odw/test_data/mweb/100 MB Studies/MRStudy/1.2.840'
    '.113619.2.5.1762583153.215519.978957063.101.dcm';
const String path0 = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';
const String path1 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String path2 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String path3 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';
const String path4 = 'C:/odw/test_data/mweb/100 MB Studies'
    '/8963-largefiles/89688';
//const String path5 = 'C:/odw/test_data/mweb/100 MB Studies'
//    '/8963-largefiles/89688';

const String path7 = 'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
    '/1.2.840.10008.5.1.4.1.1.66.dcm';
const String path8 = 'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
    '/1.2.840.10008.5.1.4.1.1.88.67.dcm';

const String path9 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2'
    '.826.0.1.3680043.2.93.1.0.1.dcm';
const String path10 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2'
    '.826.0.1.3680043.2.93.1.0.2.dcm';

const String path11 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/'
    'Anonymized1.2'
    '.840.10008.5.1.4.1.1.12.1.dcm';

const String path12 = 'C:/odw/test_data/mweb/Different_Transfer_UIDs'
    '/Anonymized1.2'
    '.840.10008.1.2.4.50.dcm';

const String path13 = 'C:/odw/test_data/mweb/Radiologic/2/I00221';
const String path14 = 'C:/odw/test_data/mweb/TransferUIDs'
    '/1.2.840.10008.1.2.4.80.dcm';

// ***** unresolved

List<String> testPaths = const <String>[
  path0, path1, path2, path3, path4, // path5, path6
  path7,
  path8, path9, path10, path0, path11, path12, path13, path14 // No reformat
];
// File with Non-Zero Prefix
const String error0 = 'C:/odw/test_data/mweb/ASPERA'
    '/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm';

// File with only 132 Bytes
const String error1 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm';

// File with only 132 Bytes
const String error2 = 'C:/odw/test_data/mweb/Radiologic/2/I00221';

// Laurel Bridge can open either.
const String error3 = 'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)'
    '/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';

// Laurel Bridge can open either.
const String error4 = "C:/odw/test_data/sfd/CT"
    "/Patient_16_CT_Maxillofacial_-_Wegners/1_DICOM_Original/IM000006.dcm";

// Laurel Bridge can open either.
const String error5 =
    "C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000003.dcm";

// Laurel Bridge can open either.
const String error6 =
    "C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original"
    "/IM000001.dcm";

// Laurel Bridge can open either.
const String error7 = "C:/odw/test_data/sfd/CT"
    "/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000004.dcm";

/// Error: cannot open file.
const String error8 = "C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT"
    ".2.16.840.1.114255.390617858.1794098916.10199.38535.dcm";

// Failed to read FMI
// It has a sequence in the FMI data.
const String error9 = "C:/odw/test_data/sfd/MG/DICOMDIR";

const String error10 = 'C:/odw/test_data/sfd/MG/Patient_38/1_DICOM_Original'
    '/IM000001.dcm';

// Odd Length Value Field
const String error11 = 'C:/odw/test_data/sfd/MG/Patient_41/1_DICOM_Original'
    '/IM000001.dcm';

const String error12 = 'C:/odw/test_data/sfd/MG/Patient_46/1_DICOM_Original'
    '/IM000003.dcm';

const String error13 = 'C:/odw/test_data/sfd/MG/Patient_48/1_DICOM_Original'
    '/IM000010.dcm';

//List<String> error6 = [];
//List<String> error6 = [];

List<String> testErrors = const <String>[
  error0, // No Reformat
  error1,
  error2,
 // error3, Fix: failed in readPixelData
  error4,
  error5,
  error6,
  error7,
  error8, // Failed to read FMI
  error9,
 // Fix error10, //read Sequence error
 // Fix error11, //read Sequence error
 // Fix error12, //read Sequence error
  // Fix error12, //read Sequence error

];

final Logger log =
    new Logger("io/bin/read_file.dart", watermark: Severity.debug2);

const List<String> defaultList = fileList0;

void main() {
  for (String path in errors) {
    try {
      File f = new File(path);
/*      FileResult r = readFileWithResult(f, fmiOnly: false);
      if (r == null) {
        log.config('No Result');
      } else {
        log.config('${r.info}');
      }*/
      readWriteCheck(f, fmiOnly: false);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}

bool readWriteCheck(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.info('Reading: $file with ${bytes0.lengthInBytes} bytes');
//  print('${bytes0.buffer.asUint8List(0, 10)}');
//  print('${bytes0.buffer.asUint8List(128, 10)}');
  if (bytes0 == null) return false;
  RootByteDataset rds0 =
      DcmByteReader.readBytes(bytes0, path: file.path, fast: true);
  if (rds0 == null) return false;
  log.info(rds0);
  Uint8List bytes1 = DcmByteWriter.write(rds0, fast: true);
//  print('${bytes1.buffer.asUint8List(0, 10)}');
//  print('${bytes1.buffer.asUint8List(128, 10)}');
  if (bytes1 == null) return false;
  bytesEqual(bytes0, bytes1);
  RootByteDataset rds1 =
      DcmByteReader.readBytes(bytes1, path: file.path, fast: true);
  return rds0 == rds1;
}

List<String> errors = [
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop"
      "/1.2.392.200036.9123.100.12.11.3.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop"
      "/1.2.840.10008.5.1.4.1.1.66.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop"
      "/1.2.840.10008.5.1.4.1.1.88.67.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop"
      "/1.2.840.10008.5.1.4.1.1.9.1.2.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)"
      "/1.2.392.200036.9123.100.12.11.3.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)"
      "/1.2.840.10008.5.1.4.1.1.66.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)"
      "/1.2.840.10008.5.1.4.1.1.88.67.dcm",
  "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)"
      "/1.2.840.10008.5.1.4.1.1.9.1.2.dcm",
  "C:/odw/test_data/mweb/Different_SOP_Class_UIDs"
      "/Anonymized1.2.826.0.1.3680043.2.93.1.0.1.dcm",
  "C:/odw/test_data/mweb/Different_SOP_Class_UIDs"
      "/Anonymized1.2.826.0.1.3680043.2.93.1.0.2.dcm",
  "C:/odw/test_data/mweb/Different_SOP_Class_UIDs"
      "/Anonymized1.2.840.10008.5.1.4.1.1.12.1.dcm",
  "C:/odw/test_data/mweb/Different_SOP_Class_UIDs"
      "/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm",
  "C:/odw/test_data/mweb/Different_SOP_Class_UIDs"
      "/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm",
  "C:/odw/test_data/mweb/Different_Transfer_UIDs"
      "/Anonymized1.2.840.10008.1.2.1.dcm",
  "C:/odw/test_data/mweb/Different_Transfer_UIDs"
      "/Anonymized1.2.840.10008.1.2.4.50.dcm",
  "C:/odw/test_data/mweb/Radiologic/2/I00221",
  "C:/odw/test_data/mweb/Radiologic/2/I00422",
  "C:/odw/test_data/mweb/Radiologic/2/I01364",
  "C:/odw/test_data/mweb/Radiologic/2/I01573",
  "C:/odw/test_data/mweb/Radiologic/6/I00422",
  "C:/odw/test_data/mweb/Radiologic/6/I00587",
  "C:/odw/test_data/mweb/Radiologic/6/I00738",
  "C:/odw/test_data/mweb/Radiologic/6/I01187",
  "C:/odw/test_data/mweb/Radiologic/6/I01573",
  "C:/odw/test_data/mweb/Sop/1.2.392.200036.9123.100.12.11.3.dcm",
  "C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.66.dcm",
  "C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm",
  "C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.9.1.2.dcm",
  "C:/odw/test_data/mweb/Sop-selected/1.2.392.200036.9123.100.12.11.3.dcm",
  "C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.66.dcm",
  "C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.88.67.dcm",
  "C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.9.1.2.dcm",
  "C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.4.80.dcm",
  "C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.5.dcm"
];
