// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';
import 'package:dataset/dataset.dart';
import 'package:dcm_convert/src/binary/base/reader/dcm_reader.dart';

abstract class DcmDebug extends DcmReader {

	DcmDebug(ByteData bd, RootDataset rds) : super(bd, rds);

}