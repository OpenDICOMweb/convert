// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:async';

import 'package:convert/src/byte_data_tools/file_list_reader.dart';
import 'package:convert/src/file_utils.dart';

const Map<String, List<String>> badTransferSyntax = const <String, List<String>>{
	'C:/odw/test_data/mweb/': const <String>[
		'ASPERA/DICOM files only/22c82bd4-6926-46e1-b055-c6b788388014.dcm',
		'ASPERA/DICOM files only/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm',
		'ASPERA/DICOM files only/523a693d-94fa-4143-babb-be8a847a38cd.dcm',
		'ASPERA/DICOM files only/613a63c7-6c0e-4fd9-b4cb-66322a48524b.dcm',
		'Different_SOP_Class_UIDs/Anonymized.dcm',
		'Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.7.dcm',
		'Different_SOP_Class_UIDs/Anonymized1.2.840.10008.5.1.4.1.1.88.67.dcm',
		'Different_Transfer_UIDs/Anonymized1.2.840.10008.1.2.2.dcm',
		'Sample Dose Sheets/4cf05f57-4893-4453-b540-4070ac1a9ffb.dcm'
	]
};

Future main() async {
	final reader = new FileListReader(badTransferSyntax);

	for (var path in reader) {
		print('"$path"');
		final bytes = await readDcmPath(path);
		if (bytes == null) continue;
		print('${bytes.lengthInBytes}: "$path"');
	}



}