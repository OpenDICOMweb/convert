// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

void main(List<String> args) {
  // var compare = new FileCompare(path1, path2);
}
//
/// helper
bool fileCompare(String path1, String path2) {
  final f1 = new File(path1);
  final f2 = new File(path2);

  final Uint8List bytes1 = f1.readAsBytesSync();
  final Uint8List bytes2 = f2.readAsBytesSync();

  return uint8ListEqual(bytes1, bytes2);
}
