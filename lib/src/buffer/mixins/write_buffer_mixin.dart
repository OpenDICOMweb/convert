// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

abstract class WriteBufferMixin {
  GrowableByteList get bList;
  Uint8List get bytes;
  ByteData get bd;

  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);
  int get lengthInBytes;
  bool get isNotEmpty;

  // **** WriteBuffer specific Getters and Methods

  int get limit => bList.limit;
  Endian get endian => bList.endian;

//  int get rIndex => rIndex_;

  bool wHasRemaining(int n) => (wIndex_ + n) <= bList.lengthInBytes;

  void setInt8(int n) => bList.setInt8(rIndex_, n);

  void writeInt8(int n) {
    assert(n >= -128 && n <= 127, 'Value out of range: $n');
    _maybeGrow(1);
    bList.setInt8(wIndex_, n);
    wIndex_++;
  }

  void setInt16(int n) => bList.setInt16(rIndex_, n);

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void writeInt16(int value) {
    assert(
        value >= -0x7FFF && value <= 0x7FFF - 1, 'Value out of range: $value');
    _maybeGrow(2);
    bList.setInt16(wIndex_, value);
    wIndex_ += 2;
  }

  void setInt32(int n) => bList.setInt32(rIndex_, n);

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void writeInt32(int value) {
    assert(value >= -0x7FFFFFFF && value <= 0x7FFFFFFF - 1,
        'Value out if range: $value');
    _maybeGrow(4);
    bList.setInt32(wIndex_, value);
    wIndex_ += 4;
  }

  void setInt64(int n) => bList.setInt64(rIndex_, n);

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void writeInt64(int value) {
    assert(value >= -0x7FFFFFFFFFFFFFFF && value <= 0x7FFFFFFFFFFFFFFF - 1,
        'Value out of range: $value');
    _maybeGrow(8);
    bList.setInt64(wIndex_, value);
    wIndex_ += 8;
  }

  void setUint8(int n) => bList.setUint8(rIndex_, n);

  /// Writes a byte (Uint8) value to _this_.
  void writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    bList.setUint8(wIndex_, value);
    wIndex_++;
  }

  void setUint16(int n) => bList.setUint16(rIndex_, n);

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    bList.setUint16(wIndex_, value);
    wIndex_ += 2;
  }

  void setUint32(int n) => bList.setUint32(rIndex_, n);

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    bList.setUint32(wIndex_, value);
    wIndex_ += 4;
  }

  void setUint64(int n) => bList.setUint64(rIndex_, n);

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void writeUint64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF,
        'Value out of range: $value');
    _maybeGrow(8);
    bList.setUint64(wIndex_, value);
    wIndex_ += 8;
  }

  /// Writes [bd] to _this_.
  void writeByteData(ByteData bd) => write(bd);

  /// Writes [bytes] to _this_.
  void writeBytes(Uint8List bytes) => write(bytes);

  /// Writes [td] to _this_.
  void write(TypedData td) {
    final offset = td.offsetInBytes;
    final length = td.lengthInBytes;
    final bytes = (td is Uint8List) ? td : td.buffer.asUint8List(offset, length);
    _maybeGrow(length);
    for (var i = 0, j = wIndex_; i < length; i++, j++)
      bytes[j] = bList[i];
    wIndex_ += length;
  }

  /// Writes [length] zeros to _this_.
  bool writeZeros(int length) {
    _maybeGrow(length);
    for (var i = 0, j = wIndex_; i < length; i++, j++) bList.bytes[j] = 0;
    wIndex_ += length;
    return true;
  }

  /// Write a DICOM Tag Code to _this_.
  void writeCode(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(wIndex_.isEven && wHasRemaining(4));
    _maybeGrow(4);
    bd
      ..setUint16(wIndex_, code >> 16)
      ..setUint16(wIndex_ + 2, code & 0xFFFF);
    wIndex_ += 4;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bList.getUint8(i) != 0) return false;
    return true;
  }

  /// Ensures that [bList] has at least [remaining] writable bytes.
  /// The [bList] is grows if necessary, and copies existing bytes into
  /// the new [bList].
  bool ensureRemaining(int remaining) => ensureCapacity(wIndex_ + remaining);

  //Urgent: move to write and read)_write_buf
  /// Ensures that [bList] is at least [capacity] long, and grows
  /// the buf if necessary, preserving existing data.
  bool ensureCapacity(int capacity) =>
      (capacity > lengthInBytes) ? grow() : false;

  bool grow([int capacity]) => bList.grow(capacity);

  /// Grow the buf if the _wIndex_ is at, or beyond, the end of the current buf.
  bool _maybeGrow([int size = 1]) =>
      (wIndex_ + size < lengthInBytes) ? false : grow(wIndex_ + size);

  /// Returns _true_ if _this_ is no longer writable.
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    if (hadTrailingBytes)
      hadTrailingZeros = checkAllZeros(wIndex_, bList.lengthInBytes);
    final bytes = bList.buffer.asByteData(0, wIndex_);
    _isClosed = true;
    return bytes;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros = false;

  void get reset {
    rIndex_ = 0;
    wIndex_ = 0;
    _isClosed = false;
    hadTrailingZeros = false;
  }

  static const int kDefaultLength = 4096;
}
