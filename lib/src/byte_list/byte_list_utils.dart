// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

// *** ByteList Internals

// Note: variables or functions named __<name> should only be used in
//       ByteList Internals section.
TypedData __td;

ByteData newBD(int length) => __td = new ByteData(length);
ByteData getByteData() => __td.buffer.asByteData();
Uint8List getBytes() => __td.buffer.asUint8List();
int getLength() => __td.lengthInBytes;

ByteData asByteData(TypedData td, int offset, int length) =>
    __td = td.buffer.asByteData(td.offsetInBytes + offset, length);

Uint8List asUint8List(TypedData td, int offset, int length) =>
    __td = td.buffer.asUint8List(td.offsetInBytes + offset, length);

// TODO: determine if this conses with a local variable.
// _bytes is used to avoid creating new Uint8List
Uint8List _bytes;
ByteData copyTypedData(TypedData td, [int offset = 0, int length]) {
  _bytes = td.buffer.asUint8List(offset, length);
  final nBytes = new Uint8List.fromList(_bytes);
  return new ByteData.view(nBytes.buffer);
}
