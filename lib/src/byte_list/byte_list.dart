// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list_mixins.dart';

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
  set length(int newLength) => throw new UnsupportedError('Fixed Length ByteList');

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

  factory ByteList({int length, Endian endian = Endian.little}) => (length == null)
      ? new GrowableByteList(length, kDefaultLimit, endian)
      : new ByteList._(length, endian);

  ByteList._(int lengthInBytes, this.endian)
      : bd = _newBD(lengthInBytes),
        bytes = _getBytes();

  factory ByteList.fromByteData(ByteData bd, [Endian endian = Endian.little]) =>
      new ByteList._fromByteData(bd, endian);

  ByteList._fromByteData(ByteData bd, this.endian)
      : bd = _asByteData(bd, 0, bd.lengthInBytes),
        bytes = _getBytes();

  ByteList.fromUint8List(Uint8List bytes, this.endian)
      : bytes = _asUint8List(bytes, 0, bytes.length),
        bd = _getByteData();
}

abstract class ImmutableMixin {
  int get length;

  void operator []=(int i, int v) =>
      throw new UnsupportedError('Cannot change the length of a fixed-length ByteList');

  set length(int newLength) =>
      throw new UnsupportedError('Cannot change the length of a fixed-length ByteList');
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

  factory ImmutableByteList({int length, Endian endian = Endian.little}) =>
      (length == null)
          ? new GrowableByteList(length, kDefaultLimit, endian)
          : new ByteList._(length, endian);

  ImmutableByteList._(int lengthInBytes, this.endian)
      : bd = _newBD(lengthInBytes),
        bytes = _getBytes();

  factory ImmutableByteList.fromByteData(ByteData bd, [Endian endian = Endian.little]) =>
      new ImmutableByteList.internal(bd, endian);

  ImmutableByteList.internal(ByteData bd, this.endian)
      : bd = _asByteData(bd, 0, bd.lengthInBytes),
        bytes = _getBytes();

  ImmutableByteList.fromUint8List(Uint8List bytes, this.endian)
      : bytes = _asUint8List(bytes, 0, bytes.length),
        bd = _getByteData();
}

ByteData _fromTypedData(TypedData td) {
  final oBytes = td.buffer.asUint8List();
  final nBytes = new Uint8List.fromList(oBytes);
  return new ByteData.view(nBytes.buffer);
}

class GrowableByteList extends ByteListBase
    with ByteListGetMixin, ByteListSetMixin
    implements Uint8List {
  static int kMaximumLength = kDefaultLimit;

  /// The upper bound on the length of this [ByteList]. If [limit]
  /// is _null_ then its length cannot be changed.
  final int limit;
  @override
  final Endian endian;
  ByteData _bd;
  Uint8List _bytes;

  GrowableByteList(int length, this.limit, this.endian)
      : _bd = _newBD(length),
        _bytes = _getBytes();

  GrowableByteList.from(GrowableByteList byteList)
      : limit = byteList.limit,
        endian = byteList.endian,
        _bd = _fromTypedData(byteList.bd),
        _bytes = _getBytes();

  GrowableByteList.fromByteData(ByteData bd,
      {this.limit = kDefaultLimit, this.endian = kDefaultEndian})
      : _bd = _asByteData(bd, 0, bd.lengthInBytes),
        _bytes = _getBytes();

  GrowableByteList.fromUint8List(Uint8List bytes,
      {this.limit = kDefaultLimit, this.endian = kDefaultEndian})
      : _bytes = _asUint8List(bytes, 0, bytes.length),
        _bd = _getByteData();

  GrowableByteList.ofSize(int length, this.limit, this.endian)
      : _bd = _newBD(length),
        _bytes = _getBytes();

  GrowableByteList.fromBD(ByteData bd, this.limit, this.endian)
      : _bd = _asByteData(bd, 0, bd.lengthInBytes),
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
