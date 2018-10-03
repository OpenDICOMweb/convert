// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

// Explicit VR Little Endian
const String x0 = 'C:/odw_test_data/mweb/Different_SOP_Class_UIDs'
    '/Anonymized1.2.840.10008.3.1.2.5.5.dcm';

// Explicit VR JPEG 2000
const String x1 =
    'C:/odw_test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

// Implicit VR
const String x2 = 'C:/odw_test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX'
    '/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)'
    '/A Aorta w-c  3.0  B20f  0-95%/IM-0001-0020.dcm';

// Explicit VR Big Endian
const String x3 =
    'C:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm';

// Explicit VR Big Endian
const String x4 = 'C:/odw_test_data/mweb/ASPERA/DICOM files only'
    '/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm';

// Explicit VR Little Endian with Private Tag codes and group length
const String x5 =
    'C:/odw_test_data/mweb/100 MB Studies/1/S234601/15859205';

const String x6 =
    'C:/odw_test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original/EFC524F2.dcm';

const String dcmDir = 'C:/odw_test_data/sfd/MG/DICOMDIR';

const String evrULength =
    'c:/odw_test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

const String x7 =
    'C:/odw_test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop'
    '/1.2.840.10008.5.1.4.1.1.88.67.dcm ';

// Defined and Undefined datasets
const String evrXLarge =
    'C:/odw_test_data/mweb/100 MB Studies/1/S234611/15859368';

const String evrOWPixels = 'C:/odw_test_data/IM-0001-0001.dcm';

const String ivrClean = 'C:/odw_test_data/sfd/MR/PID_BREASTMR/'
    '1_DICOM_Original/EFC524F2.dcm';

const String ivrCleanMR = 'C:/odw_test_data/mweb/100 MB Studies/MRStudy/'
    '1.2.840.113619.2.5.1762583153.215519.978957063.99.dcm';

const String evrDataAfterPixels =
    'C:/odw_test_data/mweb/100 MB Studies/1/S234601/15859205';

const String ivrWithGroupLengths =
    'C:/odw_test_data/mweb/100 MB Studies/MRStudy'
    '/1.2.840.113619.2.5.1762583153.215519.978957063.101.dcm';

const String bar = 'C:/odw_test_data/mweb/10 Patient IDs/04443352';

const List<String> files = <String>[
  x0, x1, x2, x3, x4, x5, x6, x7, dcmDir, evrXLarge, evrOWPixels,
  ivrClean, ivrCleanMR, evrDataAfterPixels, ivrWithGroupLengths, bar
];

const String x00 = 'c:/odw_test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/'
    '1.2.392.200036.9123.100.12.11.3.dcm';
const String x01 = 'C:/odw_test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/'
    '1.2.840.10008.5.1.4.1.1.66.dcm';
const String x02 = 'C:/odw_test_data/mweb/ASPERA/Clean_Pixel_test_data/'
    'Sop (user 349383158)/1.2.392.200036.9123.100.12.11.3.dcm';
const String x03 =
    'c:/odw_test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop (user 349383158)/1.2'
    '.840.10008.5.1.4.1.1.66.dcm';
const String x04 = 'c:/odw_test_data/mweb/ASPERA/DICOM files '
    'only/22c82bd4-6926-46e1-b055-c6b788388014.dcm';
const String x05 = 'c:/odw_test_data/mweb/ASPERA/DICOM files '
    'only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm';
const String x06 = 'c:/odw_test_data/mweb/ASPERA/DICOM files '
    'only/523a693d-94fa-4143-babb-be8a847a38cd.dcm';
const String x07 = 'c:/odw_test_data/mweb/ASPERA/DICOM files '
    'only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm';
const String x08 =
    'c:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm';
const String x09 =
    'c:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.826.0.1'
    '.3680043.2.93.1.0.1.dcm';
const String x10 =
    'c:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.826.0.1'
    '.3680043.2.93.1.0.2.dcm';
const String x11 =
    'c:/odw_test_data/mweb/Different_SOP_Class_UIDs/'
    'Anonymized1.2.840.10008.3.1.2.5.5.dcm';
const String x12 =
    'c:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.3.1'
    '.2.6.1.dcm';
const String x13 =
    'C:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840'
    '.10008.5.1.4.1.1.20.dcm';
const String x14 =
    'C:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840'
    '.10008.5.1.4.1.1.7.dcm';
const String x15 =
    'C:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840'
    '.10008.5.1.4.1.1.88.22.dcm';
const String x16 =
    'C:/odw_test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840'
    '.10008.5.1.4.1.1.88.67.dcm';
const String x17 =
    'C:/odw_test_data/mweb/Sop-selected/1.2.840.10008.5.1.4.1.1.66.dcm';

//
// This file has a Sequence with an odd length (109) that contains an Item
// with with an odd length (101)
const String mweb14 = 'C:/odw_test_data/sfd/MG/Patient_38/1_DICOM_Original/'
    'IM000001.dcm';

const List<String> badFiles = <String>[
  x00,
  x01,
  x02,
  x03,
  // x04, Big Endian
  // x05, Big Endian
  // x06, Big E
  // x07, Big E
  x08,
  x09,
  x10,
//  x11, Bad data @1878
  x12,
//  x13, //132 chars with DICM\
//  x14, Big E
//  x15, 132 chars
//  x16, Big E
  x17
];


