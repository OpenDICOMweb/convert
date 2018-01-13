// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';

abstract class ByteList extends ListBase<int> implements TypedData {
  ByteData _bd;
  static const Endianness endian = Endianness.LITTLE_ENDIAN;

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
  set length(int v) => grow(v);

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

  // The Readers
  int getInt8(int index) => _bd.getInt8(index);
  int getUint8(int index) => _bd.getUint8(index);
  int getUint16(int index) => _bd.getUint16(index, endian);
  int getInt16(int index) => _bd.getInt16(index, endian);
  int getUint32(int index) => _bd.getUint32(index, endian);
  int getInt32(int index) => _bd.getInt32(index, endian);
  int getUint64(int index) => _bd.getUint64(index, endian);
  int getInt64(int index) => _bd.getInt64(index, endian);
  double getFloat32(int index) => _bd.getFloat32(index, endian);
  double getFloat64(int index) => _bd.getFloat64(index, endian);

  // The Writers
  void setInt8(int index, int value) => _bd.setInt8(index, value);
  void setUint8(int index, int value) => _bd.setUint8(index, value);
  void setUint16(int index, int value) => _bd.setUint16(index, value, endian);
  void setInt16(int index, int value) => _bd.setInt16(index, value, endian);
  void setUint32(int index, int value) => _bd.setUint32(index, value, endian);
  void setInt32(int index, int value) => _bd.setInt32(index, value, endian);
  void setUint64(int index, int value) => _bd.setUint64(index, value, endian);
  void setInt64(int index, int value) => _bd.setInt64(index, value, endian);
  void setFloat32(int index, double value) => _bd.setFloat32(index, value, endian);
  void setFloat64(int index, double value) => _bd.setFloat64(index, value, endian);

  void setLength(int newLength) {
    if (newLength < _bd.lengthInBytes) return;
    grow(newLength);
  }

  void writeCode(int index, int code) {
    setUint16(index, code >> 16);
    setUint16(index + 2, code & 0xFFFF);
  }

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [minCapacity] is null the new buffer will be twice the size of the
  /// current buffer. If [minCapacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  bool grow([int minCapacity]) {
    log.debug('start _grow: $this');
    final oldLength = bd.lengthInBytes;
    if (minCapacity < oldLength) return false;

    var newLength = oldLength;
    if (minCapacity == null) {
      newLength = oldLength * 2;
    } else {
      while (newLength <= minCapacity) newLength *= 2;
    }
    log.debug('Grow Buffer oldLength: $oldLength newLength: $newLength');

    if (isMaxCapacityExceeded(newLength)) return false;

    final newBuffer = new ByteData(newLength);
    for (var i = 0; i < oldLength; i++) newBuffer.setUint8(i, getUint8(i));
    _bd = newBuffer;
    log.debug('end _grow ${_bd.lengthInBytes}');
    return true;
  }

  static const int kMaxByteListLength = k1GB;
  static const int kDefaultLength = 1024;
  static const int kMinByteListLength = 768;

  static const Endianness kDefaultEndian = Endianness.LITTLE_ENDIAN;

  static bool isMaxCapacityExceeded(int length, [int maxLength]) {
    maxLength ??= kMaxByteListLength;
    log.debug('isValidlength: $length');
    return (length >= maxLength);
  }

  static bool isValidBufferLength(int length, [int maxLength]) {
    maxLength ??= kMaxByteListLength;
    log.debug('isValidlength: $length');
    if (length < 1 || length > maxLength) return false;
    return true;
  }
}
