// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

void main(List<String> args) {
  print('kItem: ${hex32(kItem)} $kItem');
  print(
      'kSequenceDelimitationItem: ${hex32(kSequenceDelimitationItem)} $kSequenceDelimitationItem');
  print(
      'kItemDelimitationItem: ${hex32(kItemDelimitationItem)} $kItemDelimitationItem');
  print(
      'kUndefinedLength: ${hex32(kUndefinedLength)} '
          '$kUndefinedLength');
}
