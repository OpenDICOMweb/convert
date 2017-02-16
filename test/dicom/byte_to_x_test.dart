// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:test/test.dart';

void main() {
  simpleTest();
}

void simpleTest() {
  test("Simple BytesToX Test", () {
    int v;

    v = _bytesToWords(0);
    expect(v == 0, true);

    v = _bytesToLongs(0);
    expect(v == 0, true);

    v = _bytesToDoubles(0);
    expect(v == 0, true);

    v = _bytesToWords(2);
    //  print('v= $v');
    expect(v == 1, true);

    v = _bytesToLongs(4);
    expect(v == 1, true);

    v = _bytesToDoubles(8);
    expect(v == 1, true);

    v = _bytesToWords(16);
    expect(v == 8, true);

    v = _bytesToLongs(16);
    expect(v == 4, true);

    v = _bytesToDoubles(16);
    expect(v == 2, true);

    //TODO: fix so they catch the error
    v = _bytesToWords(15);
    expect(v != 8, true);

    v = _bytesToLongs(15);
    expect(v != 4, true);

    v = _bytesToDoubles(15);
    expect(v != 4, true);

    v = _bytesToWords(17);
    expect(v != 8, true);

    v = _bytesToLongs(17);
    expect(v != 4, true);

    v = _bytesToDoubles(17);
    expect(v != 4, true);
  });
}

/// Converts [lengthInBytes] to [length] for 2-byte value types.
int _bytesToWords(int lengthIB) =>
    ((lengthIB & 0x1) == 0) ? lengthIB >> 1 : null;

/// Converts [lengthInBytes] to [length] for 4-byte value types.
int _bytesToLongs(int lengthIB) =>
    ((lengthIB & 0x3) == 0) ? lengthIB >> 2 : null;

/// Converts [lengthInBytes] to [length] for 4-byte value types.
int _bytesToDoubles(int lengthIB) =>
    ((lengthIB & 0x7) == 0) ? lengthIB >> 3 : null;

int _lengthError(int vfLength, int sizeInBytes) {
  print('Invalid vfLength($vfLength) for elementSize($sizeInBytes)'
      'the vfLength must be evenly divisible by elementSize');
  return -1;
}
