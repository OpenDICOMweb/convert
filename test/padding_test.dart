//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
import 'package:test/test.dart';

import 'package:converter/src/binary/base/padding_chars.dart';

void main() {
  const kSpace = 32;
  const kNull = 0;
  const kInvalid = -1;

  test('Padding Char Test', () {
    for (var i = 0; i < kPaddingByVRIndex.length; i++) {
      final v = paddingChar(i);
      print('$i: $v');
    }

    expect(paddingChar(0) == kSpace, true);
    expect(paddingChar(1) == kInvalid, true);
    expect(paddingChar(2) == kInvalid, true);
    expect(paddingChar(3) == kInvalid, true);
    expect(paddingChar(4) == kInvalid, true);
    expect(paddingChar(5) == kInvalid, true);
    expect(paddingChar(6) == kInvalid, true);

    expect(paddingChar(7) == kSpace, true);
    expect(paddingChar(8) == kSpace, true);
    expect(paddingChar(9) == kSpace, true);
    expect(paddingChar(10) == kSpace, true);
    expect(paddingChar(11) == kSpace, true);
    expect(paddingChar(12) == kSpace, true);
    expect(paddingChar(13) == kSpace, true);
    expect(paddingChar(14) == kSpace, true);
    expect(paddingChar(15) == kSpace, true);
    expect(paddingChar(16) == kSpace, true);
    expect(paddingChar(17) == kSpace, true);
    expect(paddingChar(18) == kSpace, true);
    expect(paddingChar(19) == kSpace, true);
    expect(paddingChar(20) == kSpace, true);
    expect(paddingChar(21) == kSpace, true);
    expect(paddingChar(22) == kSpace, true);

    expect(paddingChar(23) == kNull, true);

    expect(paddingChar(24) == kInvalid, true);
    expect(paddingChar(25) == kInvalid, true);
    expect(paddingChar(26) == kInvalid, true);
    expect(paddingChar(27) == kInvalid, true);
    expect(paddingChar(28) == kInvalid, true);
    expect(paddingChar(29) == kInvalid, true);
    expect(paddingChar(30) == kInvalid, true);
    expect(paddingChar(31) == kInvalid, true);
    expect(paddingChar(32) == kInvalid, true);
    expect(paddingChar(33) == kInvalid, true);
    expect(paddingChar(34) == kInvalid, true);

  });
}
