// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:convert/convert.dart';
void main() {
  String crf1 = "test_data/CR.2.16.840.1.114255.393386351.1568457295.17895.5.dcm";
  String output = 'C:/odw/sdk/convert/output.dcm';

  var compare = new FileCompare(crf1, output);

  compare.compare;
}