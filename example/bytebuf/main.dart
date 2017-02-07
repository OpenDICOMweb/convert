// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

void main() {
  var a = <int>[0, 1, 2, 3];
  Uint8List b = new Uint8List.fromList(a);
  Uint8List c = b.buffer.asUint8List(1);
  Uint8List d = new Uint8List.view(c.buffer);

  print(a);
  print(b);
  print(c);
  print(d);

  a[1] = 10;
  print('\na: $a');
  print('b: $b');
  print('c: $c');

  b[1] = 20;
  print('\na: $a');
  print('b: $b');
  print('c: $c');

  c[1] = 30;
  print('\na: $a');
  print('b: $b');
  print('c: $c');
}
