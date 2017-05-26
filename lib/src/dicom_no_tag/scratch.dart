// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dictionary/dictionary.dart';
import 'package:core/core.dart';


bool _checkForDelimiter(int delimiter) {
  int code = peekTagCode();
  if (code != delimiter) return false;
  int vfLength = readUint32();
  if (vfLength != 0)
    log.warn('Pixel Data Sequence delimiter has non-zero '
        'value: $code/0x${toHex32(code)}');
  return false;
}

void _delimiterLengthFieldWarning(int dLength) {
  rootDS.hadNonZeroDelimiterLength = true;
  _log.warn('$rmm: Encountered a delimiter with a non zero length($dLength)'
      ' field');
}
