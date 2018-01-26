// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:convert/bytes/bytes.dart';

void main(List<String> args) {

  final count = 12;

  for (var i = 0; i < count; i++) {
    final a = new Bytes(count);

    assert(a.length == count, isTrue);
    for (var i = 0; i < count; i++) {
      a[i] = count;
      assert(a[i] == count, true);
  assert(a.getUint8(i) == count, true);
    }
    for (var i = 0; i < count; i++) assert(a[i] == count, true);
    for (var i = 0; i < count; i++) {
      a[i] = count + 1;
      a[i] == count + 1;
    }
    for (var i = 0; i < count; i++) {
      assert(a.getUint8(i) == a[i], true);
    }
  }
}
