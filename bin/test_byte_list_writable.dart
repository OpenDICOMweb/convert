// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

typedef TypedData _TDMaker(TypedData td, int offset, int length);

TypedData __td;

/// Returns a valid [TypedData] that is a sub-view of [td]
TypedData _checkView(TypedData td, int offset, int length, _TDMaker maker) {
  final o = td.offsetInBytes + offset;
  return __td = maker(td, o, length);
}

/// Returns a [ByteData] that is a sub-view of [td], meaning that offset
/// is relative to [td].offsetInBytes.
ByteData _asByteData(TypedData td, int offset, int length) =>
    _checkView(td, offset, length, _bdMaker);

/// Returns a [ByteData.view] of [td].
ByteData _bdMaker(TypedData td, int offset, int length) =>
    td.buffer.asByteData(offset, length);

Uint8List _asUint8List(TypedData td, int offset, int length) =>
    _checkView(td, offset, length, _bytesMaker);

Uint8List _bytesMaker(TypedData td, int offset, int length) =>
    td.buffer.asUint8List(offset, length);

// Used to avoid creating new Uint8List
Uint8List __bytes;
ByteData _copyTypedData(TypedData td, [int offset = 0, int length]) {
  final __bytes = td.buffer.asUint8List(offset, length);
  final nBytes = new Uint8List.fromList(__bytes);
  return new ByteData.view(nBytes.buffer);
}

void main() {

  final list0 = <int>[];
  print(list0);
  final list1 = new List<int>(3);
  print(list0);
//  list1.length = 4;

  final bd = new ByteData(4);
  final bytes1 = _asUint8List(bd, 1, 3);
  print('bytes1: $bytes1');
}