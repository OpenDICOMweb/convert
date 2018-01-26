// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

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

abstract class BytesBase {
  ByteData get _bd;
  Endian get endian;
}

/// [Bytes] is a class that provides a read-only byte array that supports both
/// [Uint8List] and [ByteData] interfaces.
class Bytes extends Object with ByteListGetMixin, ByteListSetMixin {
  @override
  final ByteData bd;
  @override
  final Endian endian;

  Bytes([int length = kDefaultLength, this.endian]) : bd = new ByteData(length);

  Bytes.from(Bytes bytes,
      [int offset = 0, int length, this.endian = Endian.little])
      : bd = _copy(bytes.bd, offset, length ?? bytes.lengthInBytes);

  Bytes.viewOf(Bytes bytes, [int offset = 0, int length])
      : endian = bytes.endian,
        bd = _asByteData(bytes.bd, offset, length ?? bytes.lengthInBytes);

  Bytes.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, this.endian = Endian.little])
      : bd = _copy(bytes, offset, length ?? bytes.lengthInBytes);

  Bytes.fromByteData(ByteData bd,
      [int offset = 0, int length, this.endian = Endian.little])
      : bd = _copy(bd, offset, length ?? bd.lengthInBytes);

  // *** List<int> interface
  int operator [](int i) => bd.getUint8(i);

  void operator []=(int i, int v) => bd.setUint8(i, v);

  @override
  bool operator ==(Object other) {
    if (other is Bytes) {
      if (bd.lengthInBytes != other.bd.lengthInBytes) return false;
      for (var i = 0; i < length; i++)
        if (bd.getUint8(i) != other.bd.getUint8(i)) return false;
      return true;
    }
    return false;
  }

  @override
  int get hashCode => bd.hashCode;

  int get length => bd.lengthInBytes;

  Bytes get copy => new Bytes.fromByteData(bd);

  Bytes view([int offset = 0, int length]) => new Bytes.fromByteData(
      bd.buffer.asByteData(offset, length ?? lengthInBytes));

  // **** TypedData interface.
  int get elementSizeInBytes => 1;
  int get offsetInBytes => bd.offsetInBytes;
  int get lengthInBytes => bd.lengthInBytes;
  ByteBuffer get byteBuffer => bd.buffer;

  Uint8List get uint8List => bd.buffer.asUint8List();

  static const int kDefaultLength = 1024;
}

class GrowableBytes extends Bytes {
  ByteData _bd;

  /// The upper bound on the length of this [Bytes]. If [limit]
  /// is _null_ then its length cannot be changed.
  final int limit;

  /// Returns a new [Bytes] of [length].
  GrowableBytes(int length,
      [Endian endian = Endian.little, this.limit = kDefaultLimit])
      : super(length, endian);

  /// Returns a new [Bytes] starting at [offset] of [length].
  GrowableBytes.from(GrowableBytes bytes,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      this.limit = k1GB])
      : super.from(bytes, offset, length, endian);

  /// Returns a new [Bytes] starting at [offset] of [length].
  GrowableBytes.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      this.limit = k1GB])
      : super.fromByteData(bd, offset, length, endian);

  /// Returns a new [Bytes] starting at [offset] of [length].
  GrowableBytes.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      this.limit = k1GB])
      : super.fromUint8List(bytes, offset, length, endian);

  /// Returns a new [Bytes] of [length].
  // This is only here for super classes to call
  GrowableBytes.ofSize(int length, [Endian endian, this.limit = kDefaultLimit])
      : super(length, endian);

  set bd(ByteData bd) => _bd = bd;

  set length(int newLength) {
    if (newLength < _bd.lengthInBytes) return;
    grow(newLength);
  }

  /// Ensures that [_bd] is at least [length] long, and grows
  /// the buf if necessary, preserving existing data.
  bool ensureLength(int length) => (length > lengthInBytes) ? grow() : false;

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [minLength] is null the new buffer will be twice the size of the
  /// current buffer. If [minLength] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  bool grow([int minLength]) {
    minLength ??= kMinByteListLength;
    if (minLength <= _bd.lengthInBytes) return false;

    var newLength = _bd.lengthInBytes;
    while (newLength < minLength) newLength *= 2;

    if (_isMaxCapacityExceeded(newLength)) return false;

    final newBD = new ByteData(newLength);
    for (var i = 0; i < _bd.lengthInBytes; i++)
      newBD.setUint8(i, _bd.getUint8(i));
    _bd = newBD;
    return true;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (_bd.getUint8(i) != 0) return false;
    return true;
  }

  static int kMaximumLength = kDefaultLimit;
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

ByteData _copy(TypedData td, [int offset = 0, int length]) {
  final oList = td.buffer.asUint8List(offset, length ?? td.lengthInBytes);
  final nList = new Uint8List.fromList(oList);
  return nList.buffer.asByteData();
}
