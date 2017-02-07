// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

String compareBytes(Uint8List bytes1, Uint8List bytes2) {
  for (int i = 0; i < bytes1.length; i++) {
    if (bytes1[i] != bytes2[i])
      throw "non-matching bytes at indexL $i";
  }
  //TODO: finish
  return "";
}