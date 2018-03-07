// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

const List<String> badTransferSyntaxList = const <String>[
  'C:/odw/test_data/mweb/ASP ERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
  'C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
  'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
  'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
  'C:/odw/test_data/mweb/Sample DoseSheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm'
];

const Map<String, List<String>> badTransferSyntax = const <String, List<String>>{
  'C:/odw/test_data/mweb/': const <String>[
    'ASP ERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
    'ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
    'ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
    'ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
    'Different_SOP_Class_UIDs/Anonymized.dcm',
    'Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
    'Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
    'Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
    'Sample DoseSheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm'
  ]
};


const Map<String, List<String>> badTransferSyntaxMap = const <String, List<String>>{
  '1.2.840.10008.1.2.2': const <String>[
    'C:/odw/test_data/mweb/ASP ERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
    'C:/odw/test_data/mweb/ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
    'C:/odw/test_data/mweb/ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
    'C:/odw/test_data/mweb/ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
    'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized.dcm',
    'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
    'C:/odw/test_data/mweb/Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
    'C:/odw/test_data/mweb/Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
    'C:/odw/test_data/mweb/Sample DoseSheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm'
  ]
};
