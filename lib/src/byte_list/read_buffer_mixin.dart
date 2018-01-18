// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/read_buffer.dart';

abstract class ReadBufferMixin {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.

  ByteData get bd;
  ReadBuffer rb;
  int _rIndex = 0;
  int _wIndex;
  // **** ReadBuffer specific Getters and Methods

  int get rIndex => _rIndex;

  set rIndex(int n)  {
    if (rIndex < 0 || rIndex > _wIndex)
      throw new RangeError.range(rIndex, 0, _wIndex);
    _rIndex = rIndex;
  }

  int rSkip(int n) {
    final v = _rIndex + n;
    if (v < 0 || v >= _wIndex)
      throw new RangeError.range(v, 0, _wIndex);
    return _wIndex = v;
  }

  Uint8List get contents => bd.buffer.asUint8List(bd.offsetInBytes, rIndex);

  int get rRemaining => bd.lengthInBytes - rIndex;

  bool hasRemaining(int n) => (_rIndex + n) <= _wIndex;

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;
  bool get isReadable => _isReadable;
  bool get _isReadable => _rIndex < _wIndex;

  bool get isEmpty => rRemaining <= 0;
  bool get isNotEmpty => !isEmpty;



}
