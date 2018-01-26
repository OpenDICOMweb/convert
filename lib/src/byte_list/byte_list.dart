// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list_mixins.dart';

//Urgent: Unit Test

const int k1GB = 1024 * 1024 * 1024;
const int kMinByteListLength = 16;
const int kDefaultLimit = k1GB;
const int kDefaultLength = 1024;

const Endianness kDefaultEndian = Endian.little;

bool _isMaxCapacityExceeded(int length, [int maxLength]) {
  maxLength ??= kDefaultLimit;
  return length >= maxLength;
}

/// [ByteList] is a class that provides a read-only byte array that supports both
/// [Uint8List] and [ByteData] interfaces.
abstract class ByteListBase extends ListBase<int> implements Uint8List {
  ByteData get bd;
  Uint8List get bytes;
  Endian get endian;

  // *** List<int> interface
  @override
  int operator [](int i) => bytes[i];

  @override
  void operator []=(int i, int v) => bytes[i] = v;

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
  set length(int newLength) =>
      throw new UnsupportedError('Fixed Length ByteList');

  static const int kDefaultLength = 1024;

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
class ByteList extends ByteListBase
    with ByteListGetMixin, ByteListSetMixin
    implements Uint8List {
  @override
  final ByteData bd;
  @override
  final Uint8List bytes;
  @override
  final Endian endian;

  factory ByteList({int length, Endian endian = Endian.little}) =>
      (length == null)
          ? new GrowableByteList(length, endian, kDefaultLimit)
          : new ByteList._(length, endian);

  ByteList._(int lengthInBytes, this.endian)
      : bd = _newBD(lengthInBytes),
        bytes = _getBytes();

  factory ByteList.fromByteData(ByteData bd,
          [int offset = 0, int length, Endian endian = Endian.little]) =>
      new ByteList._fromByteData(bd, offset, length, endian);

  ByteList._fromByteData(ByteData bd, [int offset = 0, int length, this.endian])
      : bd = _asByteData(bd, offset, length),
        bytes = _getBytes();

  ByteList.fromUint8List(Uint8List bytes, this.endian)
      : bytes = _asUint8List(bytes, 0, bytes.length),
        bd = _getByteData();
}

abstract class ImmutableMixin {
  int get length;

  void operator []=(int i, int v) => throw new UnsupportedError(
      'Cannot change the length of a fixed-length ByteList');

  set length(int newLength) => throw new UnsupportedError(
      'Cannot change the length of a fixed-length ByteList');
}

/// [ByteList] is a class that provides a read-only byte array that supports both
/// [Uint8List] and [ByteData] interfaces.
class ImmutableByteList extends ByteListBase
    with ImmutableMixin, ByteListGetMixin
    implements Uint8List {
  @override
  final ByteData bd;
  @override
  final Uint8List bytes;
  @override
  final Endian endian;

  ImmutableByteList(ByteData bd,
      [int offset = 0, int length, this.endian = Endian.little])
      : bd = bd.buffer.asByteData(offset, length),
        bytes = bd.buffer.asUint8List(offset, length);

  ImmutableByteList.fromUint8List(ByteData bd,
      [int offset = 0, int length, this.endian = Endian.little])
      : bd = bd.buffer.asByteData(offset, length),
        bytes = bd.buffer.asUint8List(offset, length);

  ImmutableByteList.fromTypedData(
      TypedData td, int offset, int length, this.endian)
      : bd = td.buffer.asByteData(offset, length),
        bytes = td.buffer.asUint8List(offset, length);
}

class GrowableByteList extends ByteListBase
    with ByteListGetMixin, ByteListSetMixin
    implements Uint8List {
  static int kMaximumLength = kDefaultLimit;

  /// The [Endian]ness of this [ByteList].
  @override
  final Endian endian;

  /// The upper bound on the length of this [ByteList]. If [limit]
  /// is _null_ then its length cannot be changed.
  final int limit;

  ByteData _bd;
  Uint8List _bytes;

  /// Returns a new [ByteList] of [length].
  GrowableByteList(int length,
      [this.endian = Endian.little, this.limit = kDefaultLimit])
      : _bd = _newBD(length),
        _bytes = _getBytes();

  /// Returns a new [ByteList] starting at [offset] of [length].
  GrowableByteList.from(GrowableByteList byteList,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      int limit = k1GB])
      : limit = (limit == null) ? byteList.limit : limit,
        endian = (endian == null) ? byteList.endian : endian,
        _bd = _asByteData(byteList.bd, offset, length),
        _bytes = _getBytes();

  /// Returns a new [ByteList] starting at [offset] of [length].
  GrowableByteList.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      this.endian = Endian.little,
      this.limit = k1GB])
      : _bd = _asByteData(bd, offset, length),
        _bytes = _getBytes();

  /// Returns a new [ByteList] starting at [offset] of [length].
  GrowableByteList.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      this.endian = Endian.little,
      this.limit = k1GB])
      : _bytes = _asUint8List(bytes, offset, length),
        _bd = _getByteData();

  /// Returns a new [ByteList] of [length].
  // This is only here for super classes to call
  GrowableByteList.ofSize(int length, this.endian, this.limit)
      : _bd = _newBD(length),
        _bytes = _getBytes();

  GrowableByteList.fromTypedData(
      TypedData td, int offset, int length, this.endian, this.limit)
      : _bd = _asByteData(td, offset, length),
        _bytes = _getBytes();

  @override
  int operator [](int i) {
    if (i >= _bd.lengthInBytes) grow();
    return _bytes[i];
  }

  @override
  void operator []=(int i, int v) {
    if (i >= _bytes.lengthInBytes) grow();
    _bytes[i] = v;
  }

  @override
  ByteData get bd => _bd;

  @override
  Uint8List get bytes => _bytes;

  @override
  set length(int newLength) {
    if (newLength < _bd.lengthInBytes) return;
    grow(newLength);
  }

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [minCapacity] is null the new buffer will be twice the size of the
  /// current buffer. If [minCapacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  bool grow([int minCapacity = kDefaultLength]) {
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
}

// *** Start Internals
// These should only be used in functions between Start/End Internals
TypedData __td;

ByteData _newBD(int length) => __td = new ByteData(length);
ByteData _getByteData() => __td.buffer.asByteData();
Uint8List _getBytes() => __td.buffer.asUint8List();

ByteData _asByteData(TypedData td, int offset, int length) =>
    __td = td.buffer.asByteData(td.offsetInBytes + offset, length);

Uint8List _asUint8List(TypedData td, int offset, int length) =>
    __td = td.buffer.asUint8List(td.offsetInBytes + offset, length);
