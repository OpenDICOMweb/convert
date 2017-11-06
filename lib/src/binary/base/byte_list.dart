// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

abstract class ByteList extends ListBase<int> implements TypedData {
  ByteData _bd;

  ByteList(this._bd);

  ByteData get bd => _bd;

  // **** List<int> Interface
  @override
  int operator [](int index) => _bd.getUint8(index);
  @override
  void operator []=(int index, int value) => _bd.setUint8(index, value);

  @override
  bool operator ==(Object other) {
    block:
    {
      if (other is ByteList) {
        if (length != other.length) break block;
        for (var i = 0; i < length; i++)
          if (_bd.getUint8(i) != other._bd.getUint8(i)) break block;
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode => _bd.hashCode;

  @override
  int get length => _bd.lengthInBytes;

  //Urgent: implement
  @override
  set length(int v) => throw new UnsupportedError('');

  // **** TypedData interface.
  @override
  int get elementSizeInBytes => _bd.elementSizeInBytes;
  @override
  int get offsetInBytes => _bd.offsetInBytes;
  @override
  int get lengthInBytes => _bd.lengthInBytes;

  /// Returns the underlying [ByteBuffer].
  ///
  /// The returned buffer may be replaced by operations that change the [length]
  /// of this list.
  ///
  /// The buffer may be larger than [lengthInBytes] bytes, but never smaller.
  @override
  ByteBuffer get buffer => _bd.buffer;
}
