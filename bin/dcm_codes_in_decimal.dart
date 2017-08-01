// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/number.dart';
import 'package:dictionary/dictionary.dart';

void main(List<String> args) {
  print('kItem: ${Int32.hex(kItem)} $kItem');
  print(
      'kSequenceDelimitationItem: ${Int32.hex(kSequenceDelimitationItem)} $kSequenceDelimitationItem');
  print(
      'kItemDelimitationItem: ${Int32.hex(kItemDelimitationItem)} $kItemDelimitationItem');
  print(
      'kUndefinedLength: ${Int32.hex(kUndefinedLength)} '
          '$kUndefinedLength');
}
