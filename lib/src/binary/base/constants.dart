//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:typed_data';

/// The DICOM Prefix 'DICM' as an integer.
const int kDcmPrefix = 0x4d434944;

final List<int> kPrefixAsList = Uint8List.fromList([68, 73, 67, 77]);
