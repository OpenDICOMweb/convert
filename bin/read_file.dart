// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/format.dart';
import 'package:common/logger.dart';
import 'package:convertX/convert.dart';
import 'package:convertX/src/utilities/read_file_list.dart';
import 'package:core/core.dart';

String path0 = 'C:/odw/test_data/IM-0001-0001.dcm';
String path1 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255'
    '.393386351.1568457295.17895.5.dcm';
String path2 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm';
String path3 =
    'C:/odw/test_data/sfd/CT/Patient_4_3_phase_abd/1_DICOM_Original/IM000002.dcm';
String path4 =
    'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264.20120723195848/1.2'
    '.392.200036.9125.3.3315591109239.64688154694.35921044/1.2.392.200036.9125.9.0.252688780.254812416.1536946029.dcm';
String path5 =
    'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264.20120723195848/2.16.840.1.114255.1870665029.949635505.39523.169/2.16.840.1.114255.1870665029.949635505.10220.175.dcm';
String outPath = 'C:/odw/sdk/io/example/output/out.dcm';

List<String> paths = <String>[path0, path1, path2, path3, path4, path5];

String badFile0 = "C:/odw/test_data/mweb/100 MB Studies/MRStudy/1.2.840.113619"
    ".2.5.1762583153.215519.978957063.101.dcm";

String badFile1 = "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2"
    ".840.10008.5.1.4.1.1.1.2.1.dcm";

String badFile2 = "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2"
    ".840.10008.5.1.4.1.1.104.2.dcm ";

String badFile3 = "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2"
    ".840.10008.5.1.4.1.1.128.1.dcm";

String test = 'C:/odw/sdk/test_tools/test_data/TransferUIDs'
    '/1.2.840.10008.1.2.5.dcm';
String badDir = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";
final Logger log =
    new Logger("io/bin/read_file.dart", watermark: Severity.info);

void main() {
 // readFile(badFileList2[3]);

  readFiles(badFileList4);
}

void readFile(String path) {
  File input = new File(path);
  RootDataset rds = _readFile(input);
  if (rds == null) {
    log.error('Null Instance $path');
    return null;
  }
  log.info('readFile: ${rds.info}');
  if (log.watermark == Severity.debug) formatDataset(rds);
}

void formatDataset(RootDataset rds, [bool includePrivate = true]) {
  var z = new Formatter(maxDepth: 146);
  log.debug(rds.format(z));
  for (PrivateGroup pg in rds.privateGroups)
    log.debug(pg.info);
}

void readFiles(List<String> paths) {
  log.info('Reading $paths Files:');
  var reader = new FileListReader(paths);
  reader.read;
}

RootDataset _readFile(File input) {
  Uint8List bytes = input.readAsBytesSync();
  if (bytes.length < 8 * 1024)
    log.warn('***** Short file length: ${bytes.length} - ${input.path}');
  log.debug('Reading file: $input, length: ${bytes.length}');
  RootDataset rds;
  try {
    rds = DcmDecoder.readRoot(bytes);
  } on InvalidTransferSyntaxError catch(e) {
    log.debug(e);
    return null;
  } catch(e) {
    rds = DcmDecoder.readRootNoFMI(bytes);
  }
  return rds;
}

const List<String> fileList0 = const <String>[
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.128.1.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.2.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.4.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.481.2.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.481.3.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.481.5.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.7.dcm",
"C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.88.33.dcm",
];

const List<String> badFileList1 = const <String>[
"C:/odw/test_data/mweb/ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.5.5.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.6.1.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm",
"C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm",
"C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm",
"C:/odw/test_data/mweb/Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm",
];


const List<String> badFileList2 = const <String>[
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.5.5.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.6.1.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm",
"C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm",
];

const List<String> badFileList3 = const <String>[
"C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm",
"C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm",
"C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm",
"C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm",
"C:/odw/test_data/mweb/Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm",
];

const List<String> badFileList4 = const <String>[
"C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm",
"C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm",
"C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm",
];

const List<String> fileList = const <String>[
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000001.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000002.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000003.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000004.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000005.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000006.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000007.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000008.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000009.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000010.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000011.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000012.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000014.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000015.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000016.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000017.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000018.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000019.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000020.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000021.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000022.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000023.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000001.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000002.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000003.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000004.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000006.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000007.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000008.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000009.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000010.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000011.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000012.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000013.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000014.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000015.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000016.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000017.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000018.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000019.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000002.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000003.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000004.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000005.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000006.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000007.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000008.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000009.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000010.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000011.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000012.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000013.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000014.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000015.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000016.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000017.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000018.dcm",
  "C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000019.dcm",
];
