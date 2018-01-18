// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'byte_data_mixins.dart';

//Urgent: Unit Test
//Urgent: move grow to write_buffer

typedef TypedData _TDMaker(TypedData td, int offset, int length);
// *** Start Internals
// These should only be used in functions between Start/End Internals
TypedData __td;

ByteData _newBD(int length) => __td = new ByteData(length);
ByteData _getByteData() => __td.buffer.asByteData();
Uint8List _getBytes() => __td.buffer.asUint8List();

TypedData _checkView(TypedData td, int offset, int length, _TDMaker maker) {
  final o = td.offsetInBytes + offset;
  final l = length ?? td.lengthInBytes;
  RangeError.checkValidRange(o, l, td.lengthInBytes);
  return __td = maker(td, o, l);
}

ByteData _asByteData(TypedData td, int offset, int length) =>
    _checkView(td, offset, length, _bdMaker);

ByteData _bdMaker(TypedData td, int offset, int length) =>
    td.buffer.asByteData(offset, length);

Uint8List _asUint8List(TypedData td, int offset, int length) =>
    _checkView(td, offset, length, _bytesMaker);

Uint8List _bytesMaker(TypedData td, int offset, int length) =>
    td.buffer.asUint8List(offset, length);

// *** End

const int k1GB = 1024 * 1024 * 1024;
const int kMinByteListLength = 16;
const int kMaxByteListLength = k1GB;
const int kDefaultLength = 1024;

const Endianness kDefaultEndian = Endian.little;

bool _isMaxCapacityExceeded(int length, [int maxLength]) {
  maxLength ??= kMaxByteListLength;
  return length >= maxLength;
}


/// [ByteList] is a class that provides a read-only byte array that supports both
/// [Uint8List] and [ByteData] interfaces.
abstract class ByteListBase extends ListBase<int> implements Uint8List {
  ByteData get bd;
  Uint8List get bytes;

  // *** List<int> interface
  @override
  int operator [](int i) => bytes[i];

  @override
  void operator []=(int i, int v) => throw new UnsupportedError('Read-Only list');

  @override
  bool operator ==(Object other) {
    block:
    {
      if (other is ByteList) {
        if (length != other.length) break block;
        for (var i = 0; i < length; i++)
          if (bd.getUint8(i) != other.bd.getUint8(i)) break block;
        return true;
      }
    }
    return false;
  }

  @override
  int get hashCode => bd.hashCode;

  @override
  int get length => bd.lengthInBytes;

  @override
  set length(int newLength) => throw new UnsupportedError('Immutable List');

  // **** TypedData interface.
  @override
  int get elementSizeInBytes => bd.elementSizeInBytes;
  @override
  int get offsetInBytes => bd.offsetInBytes;
  @override
  int get lengthInBytes => bd.lengthInBytes;
  @override
  ByteBuffer get buffer => bd.buffer;
}

/// [ByteList] is a class that provides a read-only byte array that supports both
/// [Uint8List] and [ByteData] interfaces.
class ByteList extends ByteListBase with ByteDataGetMixin implements Uint8List {
  @override
  final ByteData bd;
  @override
  final Uint8List bytes;

  ByteList(int lengthInBytes)
      : bd = _newBD(lengthInBytes),
        bytes = _getBytes();

  ByteList.fromByteData(ByteData bd)
      : bd = _asByteData(bd, 0, bd.lengthInBytes),
        bytes = _getBytes();

  ByteList.fromUint8List(Uint8List bytes)
      : bytes = _asUint8List(bytes, 0, bytes.length),
        bd = _getByteData();

  @override
  set length(int newLength) => throw new UnsupportedError('Immutable List');

/*  static const int k1GB = 1024 * 1024 * 1024;
  static const int kMinByteListLength = 16;
  static const int kMaxByteListLength = k1GB;
  static const int kDefaultLength = 1024;

  static const Endianness kDefaultEndian = Endianness.LITTLE_ENDIAN;

  static bool isMaxCapacityExceeded(int length, [int maxLength]) {
    maxLength ??= kMaxByteListLength;
    return length >= maxLength;
  }

  static bool isValidBufferLength(int length, [int maxLength]) {
    maxLength ??= kMaxByteListLength;
    if (length < kMinByteListLength || length > maxLength) return false;
    return true;
  }*/

  static ByteList from(ByteList byteList, [int offset = 0, int length]) =>
      new ByteList.fromByteData(_asByteData(byteList.bd, offset, length));
}

class ByteListWritable extends ByteListBase
    with ByteDataGetMixin, ByteDataSetMixin
    implements ByteData, Uint8List {
  final int maxLength;
  ByteData _bd;
  Uint8List _bytes;

  factory ByteListWritable([int length = kDefaultLength]) =>
  new ByteListWritable.internal(length, k1GB);

  ByteListWritable.internal(int length, this.maxLength)
      : _bd = _newBD(length),
        _bytes = _getBytes();

  ByteListWritable.fromByteData(ByteData bd)
      : maxLength = k1GB,
        _bd = _asByteData(bd, 0, bd.lengthInBytes),
        _bytes = _getBytes();

  ByteListWritable.fromUint8List(Uint8List bytes)
      : maxLength = k1GB,
        _bytes = _asUint8List(bytes, 0, bytes.length),
        _bd = _getByteData();

  @override
  void operator []=(int i, int v) => _bytes[i] = v;

  @override
  ByteData get bd => _bd;

  @override
  Uint8List get bytes => _bytes;
  @override
  set length(int newLength) {
    if (newLength < _bd.lengthInBytes) return;
    grow(newLength);
  }

/*
  @override
  ByteData get bd => _bd;
  @override
  Uint8List get bytes => _bytes;
*/

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [minCapacity] is null the new buffer will be twice the size of the
  /// current buffer. If [minCapacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  bool grow([int minCapacity]) {
    final oldLength = bd.lengthInBytes;
    if (minCapacity < oldLength) return false;

    var newLength = oldLength;
    if (minCapacity == null) {
      newLength = oldLength * 2;
    } else {
      while (newLength <= minCapacity) newLength *= 2;
    }

    if (_isMaxCapacityExceeded(newLength)) return false;

    final bList = new Uint8List(newLength);
    for (var i = 0; i < oldLength; i++) bList[i] = this[i];
    _bytes = bList;
    _bd = bList.buffer.asByteData();

    return true;
  }

  static ByteListWritable from(ByteListWritable byteList, [int offset = 0, int length]) {
    final bd = _asByteData(byteList._bd, offset, length);
    return new ByteListWritable.fromByteData(bd);
  }
}
