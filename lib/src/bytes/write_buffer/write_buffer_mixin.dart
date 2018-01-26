// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

abstract class WriteBufferMixin {
  GrowableBytes get bytes;

  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);
  int get lengthInBytes;
  bool get isNotEmpty;

  // **** WriteBuffer specific Getters and Methods

  int get limit => bytes.limit;
  Endian get endian => bytes.endian;

//  int get rIndex => rIndex_;

  bool wHasRemaining(int n) => (wIndex_ + n) <= bytes.lengthInBytes;

  void setInt8(int n) => bytes.setInt8(wIndex_, n);

  void writeInt8(int n) {
    assert(n >= -128 && n <= 127, 'Value out of range: $n');
    _maybeGrow(1);
    bytes.setInt8(wIndex_, n);
    wIndex_++;
  }

  void setInt16(int n) => bytes.setInt16(wIndex_, n);

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void writeInt16(int value) {
    assert(
        value >= -0x7FFF && value <= 0x7FFF - 1, 'Value out of range: $value');
    _maybeGrow(2);
    bytes.setInt16(wIndex_, value);
    wIndex_ += 2;
  }

  void setInt32(int n) => bytes.setInt32(wIndex_, n);

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void writeInt32(int value) {
    assert(value >= -0x7FFFFFFF && value <= 0x7FFFFFFF - 1,
        'Value out if range: $value');
    _maybeGrow(4);
    bytes.setInt32(wIndex_, value);
    wIndex_ += 4;
  }

  void setInt64(int n) => bytes.setInt64(wIndex_, n);

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void writeInt64(int value) {
    assert(value >= -0x7FFFFFFFFFFFFFFF && value <= 0x7FFFFFFFFFFFFFFF - 1,
        'Value out of range: $value');
    _maybeGrow(8);
    bytes.setInt64(wIndex_, value);
    wIndex_ += 8;
  }

  void setUint8(int n) => bytes.setUint8(wIndex_, n);

  /// Writes a byte (Uint8) value to _this_.
  void writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    bytes.setUint8(wIndex_, value);
    wIndex_++;
  }

  void setUint16(int n) => bytes.setUint16(wIndex_, n);

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    bytes.setUint16(wIndex_, value);
    wIndex_ += 2;
  }

  void setUint32(int n) => bytes.setUint32(wIndex_, n);

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    bytes.setUint32(wIndex_, value);
    wIndex_ += 4;
  }

  void setUint64(int n) => bytes.setUint64(wIndex_, n);

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void writeUint64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF,
        'Value out of range: $value');
    _maybeGrow(8);
    bytes.setUint64(wIndex_, value);
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
    final uint8List = (td is Uint8List) ? td : td.buffer.asUint8List(offset, length);
    _maybeGrow(length);
    for (var i = 0, j = wIndex_; i < length; i++, j++)
      bytes[j] = uint8List[i];
    wIndex_ += length;
  }

  /// Writes [length] zeros to _this_.
  bool writeZeros(int length) {
    _maybeGrow(length);
    for (var i = 0, j = wIndex_; i < length; i++, j++) bytes[j] = 0;
    wIndex_ += length;
    return true;
  }

  /// Write a DICOM Tag Code to _this_.
  void writeCode(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(wIndex_.isEven && wHasRemaining(4));
    _maybeGrow(4);
    bytes
      ..setUint16(wIndex_, code >> 16)
      ..setUint16(wIndex_ + 2, code & 0xFFFF);
    wIndex_ += 4;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bytes.getUint8(i) != 0) return false;
    return true;
  }

  /// Ensures that [bytes] has at least [remaining] writable bytes.
  /// The [bytes] is grows if necessary, and copies existing bytes into
  /// the new [bytes].
  bool ensureRemaining(int remaining) => ensureCapacity(wIndex_ + remaining);

  //Urgent: move to write and read)_write_buf
  /// Ensures that [bytes] is at least [capacity] long, and grows
  /// the buf if necessary, preserving existing data.
  bool ensureCapacity(int capacity) =>
      (capacity > lengthInBytes) ? grow() : false;

  bool grow([int capacity]) => bytes.grow(capacity);

  /// Grow the buf if the _wIndex_ is at, or beyond, the end of the current buf.
  bool _maybeGrow([int size = 1]) =>
      (wIndex_ + size < lengthInBytes) ? false : grow(wIndex_ + size);

  /// Returns _true_ if _this_ is no longer writable.
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    if (hadTrailingBytes)
      hadTrailingZeros = bytes.checkAllZeros(wIndex_, bytes.lengthInBytes);
    final bd = bytes.asByteData(0, wIndex_);
    _isClosed = true;
    return bd;
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


/// Aids to pretty printing
abstract class WriterLogMixin {
  int get wIndex;

  /// The current readIndex as a string.
  String get _www => 'W@${wIndex.toString().padLeft(5, '0')}';
  String get www => _www;

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www';

  /// The end of reading something.
  String get wee => '< $_www';

  String get pad => ''.padRight('$_www'.length);

  void warn(Object msg) => print('** Warning: $msg $_www');

  void error(Object msg) => throw new Exception('**** Error: $msg $_www');

}