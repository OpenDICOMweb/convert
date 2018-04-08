// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

// Urgent: put all the strings on one line
// ignore_for_file: no_adjacent_strings_in_list
const String test6684_01 =
    'C:/odw/test_data/36_4485_6684/IM-0001-0001-0001.dcm';
const String test6684_02 =
    'C:/odw/test_data/36_4485_6684/IM-0001-0001-0002.dcm';
const String k6684x0 =
    'C:/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';
const String k6684x1 =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

const String ivrFile =
    'C:/odw/test_data/mweb/100 MB Studies/MRStudy/1.2.840'
    '.113619.2.5.1762583153.215519.978957063.101.dcm';

// EVR, OW Pixel Data, No Private Data
const String path0 = 'C:/odw/test_data/IM-0001-0001.dcm';
// EVR, OW Pixel Data
const String path1 =
    'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';

const String path2 = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';

const String path3 =
    'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';

// Has 202 fragments
const String path4 = 'C:/odw/test_data/mweb/100 MB Studies'
    '/8963-largefiles/89688';

const String path5 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255'
    '.393386351.1568457295.17895.5.dcm';
const String path6 = 'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/'
    'CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm';
const String path7 = 'C:/odw/test_data/sfd/CT/Patient_4_3_phase_abd/'
    '1_DICOM_Original/IM000002.dcm';
const String path8 = 'C:/odw/sdk/io/example/input/'
    '1.2.840.113696.596650.500.5347264.20120723195848/1.2'
    '.392.200036.9125.3.3315591109239.64688154694.35921044/'
    '1.2.392.200036.9125.9.0.252688780.254812416.1536946029.dcm';
const String path9 = 'C:/odw/sdk/io/example/input/'
    '1.2.840.113696.596650.500.5347264.20120723195848/'
    '2.16.840.1.114255.1870665029.949635505.39523.169/'
    '2.16.840.1.114255.1870665029.949635505.10220.175.dcm';

const String path10 =
    'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
    '/1.2.840.10008.5.1.4.1.1.88.67.dcm';

const String path11 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/'
    'Anonymized1.2'
    '.840.10008.5.1.4.1.1.12.1.dcm';

const String path12 = 'C:/odw/test_data/mweb/Different_Transfer_UIDs'
    '/Anonymized1.2'
    '.840.10008.1.2.4.50.dcm';

const String path13 = 'C:/odw/test_data/mweb/Radiologic/2/I00221';

// Has non-zero preamble
const String path14 =
    'C:/odw/sdk/test_tools/test_data/TransferUIDs/1.2.840.10008.1.2.5.dcm';

const String path15 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255'
    '.393386351.1568457295.17895.5.dcm';
const String path16 = 'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/'
    'CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm';
const String path17 =
    'C:/odw/test_data/sfd/CT/Patient_4_3_phase_abd/1_DICOM_Original/IM000002.dcm';
const String path18 =
    'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264.20120723195848/1.2'
    '.392.200036.9125.3.3315591109239.64688154694.35921044/'
    '1.2.392.200036.9125.9.0.252688780.254812416.1536946029.dcm';
const String path19 =
    'C:/odw/sdk/io/example/input/1.2.840.113696.596650.500.5347264.20120723195848/'
    '2.16.840.1.114255.1870665029.949635505.39523.169/'
    '2.16.840.1.114255.1870665029.949635505.10220.175.dcm';

// Duplicate Elements, No Pixel Data
const String path20 = 'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/'
    'CT.2.16.840.1.114255.390617858.1794098916.62037.38690.dcm';

// DICOM Directory file
const String path21 = 'C:/odw/test_data/sfd/MG/DICOMDIR';

const String path22 =
    'C:/odw/test_data/sfd/MR/Patient_20_-_FMRI_brain/1_DICOM_Original.tz';

const List<String> paths = const <String>[
  path0, path1,
  //path2,
  path3, path4, path5 // No reformat
];

const List<String> testEvrPaths = const <String>[
  path0, path1,
  // path2, //Urgent: what's wrong here
  path3, path4, path5, path6, path7,
  path8, path9, path10, path11, path12, path13, path14, // No reformat
  path15, path16, path17, path18, path19, path21
];

const List<String> testIvrPaths = const <String>[path20];

const List<String> testPaths1 = const <String>[
  // IVR
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.128.1.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.4.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.481.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.481.3.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.481.5.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.7.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.88.33.dcm',
];

const List<String> testPaths2 = const <String>[
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000001.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000002.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000003.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000005.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000008.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000009.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000010.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000011.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000012.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000014.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000015.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000016.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000017.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000018.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000019.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000020.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000021.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000022.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_25_UGI_and_SBFT/1_DICOM_Original/IM000023.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000001.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000002.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000003.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000008.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000009.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000010.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000011.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000012.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000013.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000014.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000015.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000016.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000017.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000018.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_27_enema_-_ilioanal_anastomosis/1_DICOM_Original/IM000019.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000002.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000003.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000005.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000008.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000009.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000010.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000011.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000012.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000013.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000014.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000015.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000016.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000017.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000018.dcm',
  'C:/odw/test_data/sfd/CR_and_RF/Patient_31_Skeletal_survey/1_DICOM_Original/IM000019.dcm',
];

const String shortFile0 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2'
    '.826.0.1.3680043.2.93.1.0.1.dcm';
const String shortFile2 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2'
    '.826.0.1.3680043.2.93.1.0.2.dcm';

const List<String> shortFiles = const <String>[
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.826.0.1.3680043.2.93.1.0.1.dcm'
];
// File with Non-Zero Prefix
const String error0 = 'C:/odw/test_data/mweb/ASPERA'
    '/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm';

// File with only 132 Bytes
const String error1 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm';

// Laurel Bridge can open either.
const String error3 = 'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)'
    '/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';

// Laurel Bridge can open either.
const String error4 = 'C:/odw/test_data/sfd/CT'
    '/Patient_16_CT_Maxillofacial_-_Wegners/1_DICOM_Original/IM000006.dcm';

// Laurel Bridge can open either.
const String error5 =
    'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000003.dcm';

// Laurel Bridge can open either.
const String error6 =
    'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original'
    '/IM000001.dcm';

// Laurel Bridge can open either.
const String error7 = 'C:/odw/test_data/sfd/CT'
    '/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000004.dcm';

/// Error: cannot open file.
const String error8 =
    'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT'
    '.2.16.840.1.114255.390617858.1794098916.10199.38535.dcm';

// Failed to read FMI
// It has a sequence in the FMI data.
const String error9 = 'C:/odw/test_data/sfd/MG/DICOMDIR';

const String error10 = 'C:/odw/test_data/sfd/MG/Patient_38/1_DICOM_Original'
    '/IM000001.dcm';

// Odd Length Value Field
const String error11 = 'C:/odw/test_data/sfd/MG/Patient_41/1_DICOM_Original'
    '/IM000001.dcm';

const String error12 = 'C:/odw/test_data/sfd/MG/Patient_46/1_DICOM_Original'
    '/IM000003.dcm';

const String error13 = 'C:/odw/test_data/sfd/MG/Patient_48/1_DICOM_Original'
    '/IM000010.dcm';

const String error14 = 'C:/odw/test_data/mweb/TransferUIDs'
    '/1.2.840.10008.1.2.4.80.dcm';

const String error15 = 'C:/odw/test_data/sfd/XA_Neuro_IR/Patient_49/'
    '1_DICOM_Original/IM000002.dcm';

//const List<String> error6 = [];
//const List<String> error6 = [];

const List<String> testErrors = const <String>[
  error0, error1,
  //error2,
  error3, error4, error5, error6, error7, error8,
  error9, error10, error11, error12, error12, // No Reformat
];

const String badFile0 = 'C:/odw/test_data/mweb/100 MB Studies/MRStudy'
    '/1.2.840.113619.2.5.1762583153.215519.978957063.101.dcm';

const String badFile1 = 'C:/odw/test_data/mweb/ASPERA'
    '/Clean_Pixel_test_data/Sop/1.2'
    '.840.10008.5.1.4.1.1.1.2.1.dcm';

const String badFile2 = 'C:/odw/test_data/mweb/ASPERA'
    '/Clean_Pixel_test_data/Sop/1.2'
    '.840.10008.5.1.4.1.1.104.2.dcm ';

const String badFile3 = 'C:/odw/test_data/mweb/ASPERA'
    '/Clean_Pixel_test_data/Sop/1.2'
    '.840.10008.5.1.4.1.1.128.1.dcm';

const String badFile4 = 'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%'
    '/IM-0001-0020.dcm';

const String badFile5 =
    'C:/odw/test_data/sfd/Peds/Patient_55/1_DICOM_Original'
    '/IM000510.dcm';

const String badFile6 = 'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm';

const String badFile7 =
    'C:/odw/test_data/mweb/100 MB Studies/Site 3/Case 1 Ped'
    '/1.2.840.113704.1.111.8916.1202763720.15'
    '/1.2.840.113704.1.111.1608.1202763888.37524.dcm ';

const String badFile8 = 'C:/odw/test_data/mweb/100 MB Studies/MRStudy'
    '/1.2.840.113619.2.5.1762583153.215519.978957063.101.dcm';

const String badFile9 = 'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data'
    '/Sop/1.2.840.10008.5.1.4.1.1.1.2.1.dcm';

const String badFile10 =
    'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2'
    '.840.10008.5.1.4.1.1.104.2.dcm ';

const String badFile11 =
    'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2'
    '.840.10008.5.1.4.1.1.128.1.dcm';

const String badFile12 =
    'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/'
    'Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/'
    'A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';

const List<String> badFileList0 = const [
  badFile0, badFile1, badFile2, badFile3, badFile4, badFile5, badFile6,
  badFile7, badFile8, badFile9, badFile10, badFile11, badFile12 // no reformat
];

const List<String> badFileList1 = const <String>[
  'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/'
      'A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.1.2.1.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.128.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.6.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/'
      'Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.1.2.1.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/'
      'Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.128.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/'
      'Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.6.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/'
      'Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/'
      'Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0001.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0002.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0003.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0004.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0005.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0006.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0007.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0008.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0009.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0010.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0011.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0012.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0013.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0014.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0015.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0016.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0017.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0018.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0019.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0021.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0022.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0023.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0024.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0025.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0026.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0027.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0028.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0029.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0030.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0031.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0032.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0033.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0034.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0035.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0036.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0037.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0038.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0039.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0040.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0041.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0042.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0043.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0044.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0045.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0046.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0047.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0048.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0049.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0050.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0051.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0052.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0053.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0054.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0055.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0056.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0057.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0058.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0059.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0060.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0061.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0062.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0063.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0064.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0065.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0066.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0067.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0068.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0069.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0070.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0071.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0072.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0073.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0074.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0075.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0076.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0077.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0078.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0079.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0080.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0081.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0082.dcm',
  'C:/odw/test_data/mweb/COMUNIX_2/IM-0001-0083.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0001.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0002.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0003.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0004.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0005.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0006.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0007.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0008.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0009.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0010.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0011.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0012.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0013.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0014.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0015.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0016.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0017.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0018.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0019.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0021.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0022.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0023.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0024.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0025.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0026.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0027.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0028.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0029.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0030.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0031.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0032.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0033.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0034.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0035.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0036.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0037.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0038.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0039.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0040.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0041.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0042.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0043.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0044.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0045.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0046.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0047.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0048.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0049.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0050.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0051.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0052.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0053.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0054.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0055.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0056.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0057.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0058.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0059.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc  10/Projection MIP - 806/IM-0001-0060.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0001.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0002.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0003.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0004.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0005.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0006.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0007.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0008.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0009.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0010.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0011.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0012.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0013.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0014.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0015.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0016.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0017.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0018.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0019.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0021.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0022.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0023.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0024.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0025.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0026.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0027.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0028.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0029.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0030.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0031.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0032.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0033.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0034.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0035.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0036.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0037.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0038.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0039.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0040.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0041.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0042.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0043.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0044.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0045.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0046.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0047.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0048.dcm',
  'C:/odw/test_data/mweb/Dicom files2/PET PETCT_WB_apc (Adult) --7 Series/mpr.cor.pet - 605/IM-0001-0049.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.1.2.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.1.2.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.11.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.3.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.6.1.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.4.70.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.4.90.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.1.2.1.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.128.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.6.2.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.1.2.1.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.128.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.6.2.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
];

const List<String> badFileList2 = const <String>[
  'C:/odw/test_data/mweb/100 MB Studies/Brain026/ST000000/SE000000/IM000000.png',
  'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/35196654Phase2/ST-8955934202186539155/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/35196654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/56406654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/59516654Phase2/ST-3319147862064506277/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/59516654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/73856654Phase2/ST-4792088524786772475/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/73856654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTID 2.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTID 3.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTID 4.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTIDs.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 Protocol.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP2 questionaire.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 agreement.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 CTIDs.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 PS info.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 Questionaire.pdf',
  'C:/odw/test_data/mweb/New Dicom Files/Neuro Crane-7 over/Debug_Rolling.log',
  'C:/odw/test_data/mweb/New Dicom Files/Neuro Crane-7 over/OQ 4.3 SP1 Hotfix Release.zip',
  'C:/odw/test_data/mweb/New Dicom Files/Neuro Crane-7 over/Top_Users_Rport.html',
  'C:/odw/test_data/mweb/Small Studies/BBC-0010-C US/1_timeseries.png',
  'C:/odw/test_data/mweb/Small Studies/BBC-0010-C US/1_timeseries2.png',
];

const List<String> badFileList3 = const <String>[
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm',
  'C:/odw/test_data/sfd/CT/Patient_16_CT_Maxillofacial_-_Wegners/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CT/Patient_16_CT_Maxillofacial_-_Wegners/1_DICOM_Original/IM000005.dcm',
  'C:/odw/test_data/sfd/CT/Patient_16_CT_Maxillofacial_-_Wegners/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CT/Patient_16_CT_Maxillofacial_-_Wegners/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000003.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000005.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000008.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000009.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000010.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000011.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000012.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000013.dcm',
  'C:/odw/test_data/sfd/CT/Patient_6_Lung_CA/1_DICOM_Original/IM000014.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000001.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000005.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000011.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000012.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM000013.dcm',
  'C:/odw/test_data/sfd/CT/Patient_7_Dural_Ectasia/1_DICOM_Original/IM001884.dcm',
  'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000004.dcm',
  'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000005.dcm',
  'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000006.dcm',
  'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000007.dcm',
  'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000008.dcm',
  'C:/odw/test_data/sfd/CT/Patient_8_Non_ossifying_fibroma/1_DICOM_Original/IM000009.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10199.38535.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10309.38358.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10340.38552.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10418.38411.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10537.38256.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10561.38575.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10818.38285.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.10993.38472.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.1109.38363.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.11113.38605.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.11133.38219.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.1126.38525.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.11268.38272.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.11328.38438.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.11994.38315.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.12173.38613.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.12310.38399.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.12510.38412.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.12622.38585.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.12789.38427.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.12936.38406.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.1338.38607.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13440.38666.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13662.38381.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13670.38382.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13678.38324.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13688.38452.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13693.38641.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13736.38262.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13783.38646.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13805.38225.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13845.38407.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.1392.38432.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.13940.38642.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.14092.38491.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.14189.38410.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.14495.38215.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.14752.38495.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15043.38533.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15133.38353.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15191.38479.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15214.38447.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15285.38508.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15527.38689.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15643.38310.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.15734.38674.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16044.38636.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16079.38384.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16175.38630.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16189.38481.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16191.38361.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16278.38647.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16333.38462.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16352.38439.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16404.38350.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16464.38282.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.16778.38294.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17115.38337.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17199.38386.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17553.38590.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17720.38528.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17842.38418.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17966.38693.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.17988.38305.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18085.38597.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18295.38286.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18316.38673.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18338.38687.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18443.38405.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18877.38541.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.18947.38328.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19026.38551.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19227.38683.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19457.38637.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19490.38297.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19742.38288.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19770.38250.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19902.38248.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.19986.38373.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.20024.38589.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.20185.38302.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.20712.38257.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.20721.38584.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2090.38615.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.21314.38335.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.21364.38685.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.21416.38223.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.21485.38566.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.21512.38686.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2158.38448.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.22084.38409.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.22150.38660.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.22175.38229.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.22508.38561.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.22511.38392.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2271.38639.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.22816.38485.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23081.38503.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23115.38298.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23176.38548.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23288.38321.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23417.38306.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23453.38602.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23456.38247.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23466.38632.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23483.38415.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23660.38231.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23813.38444.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23950.38581.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.23986.38352.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.24131.38460.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.24456.38293.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.24893.38295.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.24942.38506.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.25084.38553.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2509.38424.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2516.38314.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.25404.38598.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.25628.38319.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.25636.38260.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.25682.38450.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.25937.38258.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2639.38516.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.26495.38651.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.26513.38242.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.26555.38218.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.26827.38243.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2695.38421.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.26977.38670.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27002.38669.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2704.38362.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27206.38378.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27282.38398.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27297.38558.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27352.38619.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27508.38505.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27658.38490.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27748.38227.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27752.38625.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27920.38611.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27952.38559.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.27975.38504.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.2799.38267.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.28549.38573.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.28633.38618.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.28705.38275.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.28858.38402.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.28886.38629.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29046.38234.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29106.38309.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29134.38521.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29302.38531.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29483.38688.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29552.38549.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29686.38520.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29705.38425.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.29828.38351.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.30114.38307.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.30606.38429.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.3065.38582.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.3066.38441.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.30710.38667.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31047.38587.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31050.38413.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31053.38437.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31078.38523.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31146.38349.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31213.38333.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31243.38471.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31597.38239.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31622.38326.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31763.38663.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31813.38237.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31964.38238.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.31994.38664.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.3205.38404.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.32108.38624.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.32443.38671.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.32771.38662.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.32813.38230.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.32833.38387.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33232.38270.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33259.38391.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33335.38435.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33503.38291.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33656.38428.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33660.38654.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33673.38578.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33679.38370.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33698.38501.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.33801.38278.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34299.38620.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34435.38645.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34502.38264.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34611.38550.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34670.38336.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34794.38346.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.34941.38401.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.35057.38240.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.35586.38216.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.35739.38268.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36189.38509.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36267.38320.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36311.38355.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36449.38522.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36532.38530.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36535.38332.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36586.38678.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36765.38554.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36782.38366.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36847.38451.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.36916.38217.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37258.38211.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37270.38289.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37435.38322.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37544.38431.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37551.38261.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.3757.38496.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37586.38277.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37695.38538.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37746.38224.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37863.38334.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.37952.38394.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38057.38676.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38067.38570.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38074.38547.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38191.38588.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38511.38449.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38593.38283.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38624.38273.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38772.38263.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.38819.38376.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.3886.38274.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.3953.38562.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.39552.38514.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.39703.38367.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.39950.38379.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40020.38434.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40159.38330.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40468.38368.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40596.38365.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40596.38461.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40623.38395.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4063.38417.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40838.38371.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.40936.38246.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41020.38608.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41081.38299.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41213.38540.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41225.38635.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4131.38492.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41425.38652.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4144.38665.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41482.38390.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41717.38527.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4175.38393.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41765.38470.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41824.38325.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4183.38511.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.41909.38563.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42129.38445.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42297.38592.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42325.38292.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42371.38569.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42426.38616.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42520.38455.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42546.38640.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42603.38316.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42856.38649.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42864.38568.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.42917.38426.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.43039.38633.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.43645.38430.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.43713.38241.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.43820.38494.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.43936.38577.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44021.38532.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44115.38638.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44260.38433.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44418.38681.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44453.38369.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44510.38469.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44681.38677.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44787.38467.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.44874.38357.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45041.38555.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45321.38626.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45436.38269.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45489.38287.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45575.38254.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45649.38244.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45744.38464.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.45848.38661.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4617.38458.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4618.38656.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.4626.38692.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.46604.38408.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.46692.38524.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.46932.38675.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.46960.38478.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47193.38423.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47223.38463.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47297.38290.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47326.38659.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47391.38436.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47419.38339.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47438.38318.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47467.38486.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47869.38502.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.479.38364.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.47973.38308.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48246.38245.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48247.38526.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48275.38510.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48505.38443.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48590.38341.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48636.38284.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48755.38627.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.48924.38484.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.49022.38459.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.49058.38311.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.49160.38312.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.49278.38483.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.49309.38453.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.49548.38236.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.50146.38545.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.50334.38571.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.50410.38513.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.50464.38557.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.50480.38303.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.50513.38456.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51070.38480.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51072.38593.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51084.38340.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51140.38657.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51196.38476.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51334.38539.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51347.38323.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51602.38614.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51787.38658.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.51949.38586.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52089.38493.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52164.38327.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52247.38400.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5249.38454.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52508.38628.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52518.38389.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52599.38420.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52840.38385.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.52936.38342.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53009.38281.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53110.38468.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53145.38556.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53154.38457.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5317.38594.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53306.38517.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53329.38440.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53537.38259.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53551.38621.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53617.38482.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53961.38560.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.53974.38648.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.54193.38397.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5423.38604.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.54323.38601.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.54640.38634.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.54802.38684.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.54992.38537.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.55107.38679.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.55320.38580.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.55710.38377.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.55720.38596.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.55724.38403.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.55910.38388.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.56176.38576.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.56258.38600.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.56283.38345.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.56573.38446.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.56777.38631.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.56900.38610.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57001.38507.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57142.38226.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57446.38617.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57533.38296.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57633.38579.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57649.38567.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57790.38419.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57860.38606.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57905.38252.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57959.38301.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.57984.38612.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.58079.38265.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.58160.38222.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5826.38372.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5830.38276.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.58450.38599.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.58567.38595.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5868.38329.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.59093.38487.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.59203.38271.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.59672.38488.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.5981.38564.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60176.38210.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60212.38253.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60258.38414.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60360.38233.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60384.38500.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60427.38304.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60547.38416.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60698.38489.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.60887.38232.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61104.38643.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61146.38360.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6121.38519.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61224.38655.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61386.38465.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6140.38212.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61568.38251.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61584.38572.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61756.38623.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.61826.38344.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62037.38690.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62039.38497.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62076.38515.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62136.38574.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62400.38644.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62416.38220.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6243.38380.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.62719.38266.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63018.38313.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63210.38475.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63360.38546.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63424.38499.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63460.38255.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63512.38682.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63529.38348.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63653.38338.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63854.38544.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63905.38653.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.63915.38583.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64085.38422.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64262.38622.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64341.38221.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64465.38359.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64499.38317.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6450.38591.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64713.38474.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.64969.38300.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.65088.38542.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.65436.38343.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6565.38375.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6900.38442.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6926.38650.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6935.38214.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.6953.38396.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.7003.38473.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.7344.38213.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.7423.38609.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.766.38543.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.7925.38354.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.797.38565.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8094.38280.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.811.38672.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8122.38529.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8140.38680.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8190.38347.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8222.38512.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.825.38466.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8288.38691.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8547.38249.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.8798.38331.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.880.38228.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.886.38356.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9087.38279.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9230.38235.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9232.38518.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9338.38536.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9455.38477.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9456.38498.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9573.38534.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9725.38668.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9811.38383.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9844.38603.dcm',
  'C:/odw/test_data/sfd/CT/PID_MINT9/1_DICOM_Original/CT.2.16.840.1.114255.390617858.1794098916.9955.38374.dcm',
  'C:/odw/test_data/sfd/Peds/Patient_55/1_DICOM_Original/IM000510.dcm',
];

const List<String> badFileList4 = const <String>[
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.5.5.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.6.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
  'C:/odw/test_data/mweb/Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
];

const List<String> badFileList5 = const <String>[
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.5.5.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1.2.6.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm',
];

const List<String> badFileList6 = const <String>[
  'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
  'C:/odw/test_data/mweb/Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
];

const List<String> badFileList7 = const <String>[
  'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm',
];

const List<String> badFileList8 = const <String>[
  'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205',
  'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368',
  'C:/odw/test_data/mweb/100 MB Studies/8963-largefiles/89688',
  'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case1 [Case1]/20080408 023126 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.69.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case10 [Case10]/20080708 033624 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.97.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case10 [Case10]/20080708 033624 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.99.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case11 [Case11]/20080625 031326 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.120.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case12 [Case12]/20081202 021026 [ - Combo Unilateral Left]/Series 73111100 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.148.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case12 [Case12]/20081202 021026 [ - Combo Unilateral Left]/Series 73112200 [MG - L ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.150.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case13 [Case13]/20080716 034953 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.178.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case13 [Case13]/20080716 034953 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - R ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.180.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case14 [Case14]/20080915 034948 [ - DUCTO GALACTOGRAM 1 DUCT LT]/Series 73111100 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.44.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case14 [Case14]/20080915 034948 [ - DUCTO GALACTOGRAM 1 DUCT LT]/Series 73112300 [MG - L LM Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.46.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case14 [Case14]/20080915 082127 [ - MAMMOGRAM DIGITAL DX BILAT]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.36.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case14 [Case14]/20080915 082127 [ - MAMMOGRAM DIGITAL DX BILAT]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.38.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case14 [Case14]/20080915 082127 [ - MAMMOGRAM DIGITAL DX BILAT]/Series 73100000 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.40.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case14 [Case14]/20080915 082127 [ - MAMMOGRAM DIGITAL DX BILAT]/Series 73100000 [MG - R MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.42.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case15 [Case15]/20080312 025831 [ - MAMMOGRAM DIGITAL DX UNILAT RT]/Series 73100000 [MG - R ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.208.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case15 [Case15]/20080312 025831 [ - MAMMOGRAM DIGITAL DX UNILAT RT]/Series 73100000 [MG - R XCCL Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.210.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case16 [Case16]/20081021 024920 [ - Combo Unilateral Right]/Series 73121100 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.238.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case16 [Case16]/20081021 024920 [ - Combo Unilateral Right]/Series 73122200 [MG - R ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.240.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case17 [Case17]/20080514 041955 [ - MAMMOGRAM DIGITAL DX UNILAT LT]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.275.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case17 [Case17]/20080514 041955 [ - MAMMOGRAM DIGITAL DX UNILAT LT]/Series 73100000 [MG - L ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.277.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case17 [Case17]/20080514 103944 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.279.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case2 [Case2]/20071120 080520 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.392.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case2 [Case2]/20071120 080520 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.394.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case2 [Case2]/20071120 080520 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.396.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case2 [Case2]/20071120 080520 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - R MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.398.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case20 [Case20]/20080527 064103 [ - COMBO BILAT]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.433.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case20 [Case20]/20080527 064103 [ - COMBO BILAT]/Series 73100000 [MG - L ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.435.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case20 [Case20]/20080527 064103 [ - COMBO BILAT]/Series 73100000 [MG - R ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.437.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case3 [Case3]/20071120 034906 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.543.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case3 [Case3]/20071120 034906 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.545.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case3 [Case3]/20071120 034906 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.547.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case3 [Case3]/20071120 034906 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - R MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.549.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case4 [Case4]/20071218 093012 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.585.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case4 [Case4]/20071218 093012 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - L MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.587.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case4 [Case4]/20071218 093012 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.589.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case4 [Case4]/20071218 093012 [ - MAMMOGRAM DIGITAL SCR BILAT]/Series 73100000 [MG - R MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.591.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case5 [Case5]/20071127 035303 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.615.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case5 [Case5]/20071127 035303 [ - BREAST IMAGING TOMOSYNTHESIS]/Series 73100000 [MG - L ML Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.617.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case8 [Case8]/20080629 090944 [ - Standard Screening  Combo]/Series 73100000 [MG - R MLO Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.710.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case9 [Case9]/20080610 073024 [ - Combo Unilateral Right]/Series 73100000 [MG - R CC Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.744.0.dcm',
  'C:/odw/test_data/mweb/DICOMTestdata/Case9 [Case9]/20080610 073024 [ - Combo Unilateral Right]/Series 73100000 [MG - R LM Tomosynthesis Reconstruction]/1.3.6.1.4.1.5962.99.1.2280943358.716200484.1363785608958.746.0.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.826.0.1.3680043.2.93.1.0.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.826.0.1.3680043.2.93.1.0.2.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.12.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.1.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.4.50.dcm',
  'C:/odw/test_data/mweb/Radiologic/2/I00221',
  'C:/odw/test_data/mweb/Radiologic/2/I00422',
  'C:/odw/test_data/mweb/Radiologic/2/I00587',
  'C:/odw/test_data/mweb/Radiologic/2/I00738',
  'C:/odw/test_data/mweb/Radiologic/2/I00895',
  'C:/odw/test_data/mweb/Radiologic/2/I00994',
  'C:/odw/test_data/mweb/Radiologic/2/I01132',
  'C:/odw/test_data/mweb/Radiologic/2/I01187',
  'C:/odw/test_data/mweb/Radiologic/2/I01364',
  'C:/odw/test_data/mweb/Radiologic/2/I01573',
  'C:/odw/test_data/mweb/Radiologic/6/I00422',
  'C:/odw/test_data/mweb/Radiologic/6/I00587',
  'C:/odw/test_data/mweb/Radiologic/6/I00738',
  'C:/odw/test_data/mweb/Radiologic/6/I00895',
  'C:/odw/test_data/mweb/Radiologic/6/I00994',
  'C:/odw/test_data/mweb/Radiologic/6/I01132',
  'C:/odw/test_data/mweb/Radiologic/6/I01187',
  'C:/odw/test_data/mweb/Radiologic/6/I01573',
  'C:/odw/test_data/mweb/Radiologic/7/I00005',
  'C:/odw/test_data/mweb/Radiologic/7/I00265',
  'C:/odw/test_data/mweb/Radiologic/7/I00455',
  'C:/odw/test_data/mweb/Radiologic/7/I00715',
  'C:/odw/test_data/mweb/Radiologic/7/I00988',
  'C:/odw/test_data/mweb/Radiologic/7/I01223',
  'C:/odw/test_data/mweb/Radiologic/7/I01454',
  'C:/odw/test_data/mweb/Radiologic/7/I01745',
  'C:/odw/test_data/mweb/Sop/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.4.80.dcm',
  'C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.4.90.dcm',
  'C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.5.dcm'
];

const List<String> badFileList9 = const <String>[
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
      '/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
      '/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
      '/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
      '/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)'
      '/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)'
      '/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)'
      '/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)'
      '/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
      '/Anonymized1.2.826.0.1.3680043.2.93.1.0.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
      '/Anonymized1.2.826.0.1.3680043.2.93.1.0.2.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
      '/Anonymized1.2.840.10008.5.1.4.1.1.12.1.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
      '/Anonymized1.2.840.10008.5.1.4.1.1.20.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs'
      '/Anonymized1.2.840.10008.5.1.4.1.1.88.22.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs'
      '/Anonymized1.2.840.10008.1.2.1.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs'
      '/Anonymized1.2.840.10008.1.2.4.50.dcm',
  'C:/odw/test_data/mweb/Radiologic/2/I00221',
  'C:/odw/test_data/mweb/Radiologic/2/I00422',
  'C:/odw/test_data/mweb/Radiologic/2/I01364',
  'C:/odw/test_data/mweb/Radiologic/2/I01573',
  'C:/odw/test_data/mweb/Radiologic/6/I00422',
  'C:/odw/test_data/mweb/Radiologic/6/I00587',
  'C:/odw/test_data/mweb/Radiologic/6/I00738',
  'C:/odw/test_data/mweb/Radiologic/6/I01187',
  'C:/odw/test_data/mweb/Radiologic/6/I01573',
  'C:/odw/test_data/mweb/Sop/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Sop/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.392.200036.9123.100.12.11.3.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.66.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.9.1.2.dcm',
  'C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.4.80.dcm',
  'C:/odw/test_data/mweb/TransferUIDs/1.2.840.10008.1.2.5.dcm'
];

const List<String> badExtensions = const <String>[
  'C:/odw/test_data/mweb/10 Patient IDs'
      '/GECRSENODMRFUJI_1.CR.1001.1002.2008'
      '.03.10.13.06.53.62500.12180812.IMA',
  'C:/odw/test_data/mweb/100 MB Studies/Brain026/ST000000/SE000000/IM000000.png',
  'C:/odw/test_data/mweb/100 MB Studies/Brain026/ST000000/SE000002/.dcm.IM000194',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/35196654Phase2'
      '/ST-8955934202186539155/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/35196654Phase2/__guests.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/35196654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/56406654Phase2/__guests.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/56406654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/59516654Phase2'
      '/ST-3319147862064506277/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/59516654Phase2/__guests.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/59516654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/73856654Phase2'
      '/ST-4792088524786772475/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/73856654Phase2/__guests.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Samples for IROC/73856654Phase2/__index.xml',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTID 2.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTID 3.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTID 4.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 CTIDs.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP 2 Protocol.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 2/CTCAP2 questionaire.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 agreement.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 CTIDs.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 PS info.pdf',
  'C:/odw/test_data/mweb/500 MB Studies/Site 4/Site 4 Paperwork/CTCAP 4 Questionaire.pdf',
  'C:/odw/test_data/mweb/New Dicom Files/Neuro Crane-7 over/Debug_Rolling.log',
  'C:/odw/test_data/mweb/New Dicom Files/Neuro Crane-7 over/OQ 4.3 SP1 Hotfix Release.zip',
  'C:/odw/test_data/mweb/New Dicom Files/Neuro Crane-7 over/Top_Users_Rport.html',
  'C:/odw/test_data/mweb/Small Studies/BBC-0010-C US/1_timeseries.png',
  'C:/odw/test_data/mweb/Small Studies/BBC-0010-C US/1_timeseries2.png',
  'C:/odw/test_data/mweb/Small Studies/Two Studies/ARGLH001.DCM'
];

const List<String> bigEndianTS = const <String>[
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
  'C:/odw/test_data/mweb/Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm'
];

const List<String> badTSFileList = const <String>[
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
  'C:/odw/test_data/mweb/Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
];
