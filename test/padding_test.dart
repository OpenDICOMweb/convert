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
  test('Padding Char Test', () {
    for (var i = 0; i < kPaddingByVRIndex.length; i++) {
      final v = paddingChar(i);
      print('$i: $v');
    }

    expect(paddingChar(0) == -1, true);
    expect(paddingChar(1) == -1, true);
    expect(paddingChar(2) == -1, true);
    expect(paddingChar(3) == -1, true);
    expect(paddingChar(4) == -1, true);
    expect(paddingChar(5) == -1, true);
    expect(paddingChar(6) == -1, true);

    expect(paddingChar(7) == 32, true);
    expect(paddingChar(8) == 32, true);
    expect(paddingChar(9) == 32, true);
    expect(paddingChar(10) == 32, true);
    expect(paddingChar(11) == 32, true);
    expect(paddingChar(12) == 32, true);
    expect(paddingChar(13) == 32, true);
    expect(paddingChar(14) == 32, true);
    expect(paddingChar(15) == 32, true);
    expect(paddingChar(16) == 32, true);
    expect(paddingChar(17) == 32, true);
    expect(paddingChar(18) == 32, true);
    expect(paddingChar(19) == 32, true);
    expect(paddingChar(20) == 32, true);
    expect(paddingChar(21) == 32, true);
    expect(paddingChar(22) == 32, true);

    expect(paddingChar(23) == 0, true);

    expect(paddingChar(24) == -1, true);
    expect(paddingChar(25) == -1, true);
    expect(paddingChar(26) == -1, true);
    expect(paddingChar(27) == -1, true);
    expect(paddingChar(28) == -1, true);
    expect(paddingChar(29) == -1, true);
    expect(paddingChar(30) == -1, true);
    expect(paddingChar(31) == -1, true);
    expect(paddingChar(32) == -1, true);
    expect(paddingChar(33) == -1, true);
    expect(paddingChar(34) == -1, true);

  });
}
