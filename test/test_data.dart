//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

const String path0 = 'C:/odw_test_data/mweb/10 Patient IDs'
    '/2a5bef0f-e4d2-4680-bd24-f42d902d6741.dcm';
const String path1 = 'C:/odw_test_data/mweb/TransferUIDs'
    '/1.2.840.10008.1.2.4.100.dcm';
const String path2 = 'C:/odw_test_data/mweb/TransferUIDs'
    '/1.2.840.10008.1.2.5.dcm';
const String path3 = 'C:/odw_test_data/mweb/ASPERA/'
    'Clean_Pixel_test_data/RTOG Study/'
    'RTP_2.25.369465182237858466013782274173253459938.1.dcm';
const String path4 = 'C:/odw_test_data/mweb/ASPERA/DICOM files only/'
    '22f01f4d-32c0-4a13-9350-9f0b4390889b.dcm';
const String path5 =
    'C:/odw_test_data/6684/2017/5/13/4/888A5773/2463BF1A/2463C2DB';
const String path6 = 'C:/odw_test_data/mweb/Sample Dose Sheets/'
    '4cfc6ccc-2a8c-4af4-beb6-c4968fbb10d0.dcm';

// Implicit Little Endian
const String path7 = 'C:/odw_test_data/mweb/Sample Dose Sheets/'
    '1d7fa0b8-06a7-4eef-9486-9e3ac3347eae.dcm';

// Urgent Jim: read error here
const String path8 = 'C:/odw_test_data/mweb/Sample Dose Sheets/'
    '4e627a0a-7ac2-4c44-8a3e-6515951fc6bb.dcm';

const String path9 = 'C:/odw_test_data/mweb/500+/'
    'PET PETCT_CTplusFET_LM_Brain (Adult)/'
    'dynamic recon 3x10min Volume (Corrected) - 7/IM-0001-0218.dcm';

const List<String> paths = [
  path0, path1, path2, path3, path4, // no reformat
  path5, path6, path7, path8, path9,
];
