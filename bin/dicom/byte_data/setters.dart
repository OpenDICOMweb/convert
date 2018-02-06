// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';

void main(List<String> args) {

  final floats = <double>[0.0, 1.0, 2.0, 3.0];
  final fl32List0 = new Float32List.fromList(floats);
  final fl32Bytes0= new Bytes.fromTypedData(fl32List0);
  assert(fl32Bytes0.getFloat32(0) == fl32List0[0]);
  assert(fl32Bytes0.getFloat32(4) == fl32List0[1]);
  assert(fl32Bytes0.getFloat32(8) == fl32List0[2]);
  assert(fl32Bytes0.getFloat32(12) == fl32List0[3]);

  //  final fl32List1 =
  final fl32List1 = fl32Bytes0.asFloat32List();

  for (var i = 0; i < fl32List0.length; i++)
    assert(fl32List0[i] == fl32List1[i]);

  // Unaligned
  final fl32b = new Bytes(20)
  ..setFloat32(2, floats[0])
  ..setFloat32(6, floats[1])
  ..setFloat32(10, floats[2])
  ..setFloat32(14, floats[3]);
  assert(fl32b.getFloat32(2) == fl32List0[0]);
  assert(fl32b.getFloat32(6) == fl32List0[1]);
  assert(fl32b.getFloat32(10) == fl32List0[2]);
  assert(fl32b.getFloat32(14) == fl32List0[3]);

  final fl32List3 = fl32b.getFloat32List(2, 4);

  for (var i = 0; i < fl32List0.length; i++)
    assert(fl32List0[i] == fl32List3[i]);


/*
  final float64 = new Float64List.fromList(floats);
  final fl64List0 = new Bytes.fromTypedData(float32);
  final fl64a = new Bytes(fl64List0.lengthInBytes);
  final fl64List1 = fl64a.asFloat64List();

*/

}



