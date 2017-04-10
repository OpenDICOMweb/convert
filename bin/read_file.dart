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

String badDir = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";
final Logger log =
    new Logger("io/bin/read_file.dart", watermark: Severity.debug);

void main() {
 readFile(badFile1);

 // log.info('Reading ${fileList.length} Files:');
 // readFiles(fileList);
}

void readFile(String path) {
  File input = new File(path);
  Instance instance;
  try {
    instance = _readFile(input);
  } catch(e) {
    log.error('Could not read "$path": $e');
    return null;
  }
  if (instance == null) {
    log.error('Null Instance $path');
    return null;
  }
  log.info('readFile: ${instance.info}');
  var z = new Formatter(maxDepth: 146);
  log.debug(instance.format(z));
  //TODO: make this work
  for(PrivateGroup pg in instance.dataset.privateGroups) log.debug(pg.info);
  // for (PrivateGroup pg in instance.dataset.privateGroups)
  //  log.debug(pg.format(z));
}

void readFiles(List<String> paths) {
  bool throwOnError = true;
  File input;
  for (String path in paths) {
    try {
      input = new File(path);
      Instance instance = _readFile(input);
      log.info('${instance.info}');
    } catch (e) {
      log.info('File: $input');
      log.info('e: $e');
      if (throwOnError) rethrow;
      return;
    }
  }
}

Instance _readFile(File input) {
  Uint8List bytes = input.readAsBytesSync();
  log.debug('Reading file: $input');
  log.debug('File bytes length: ${bytes.length}');
  Instance instance = DcmDecoder.decode(new DSSource(bytes, input.path));

  return instance;
}

List<String> fileList = const <String>[
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