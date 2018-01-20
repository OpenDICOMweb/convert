// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';

// ignore_for_file: non_constant_identifier_names

abstract class WriteBufferMixin {
  GrowableByteList wb;

  int rIndex_;
  int wIndex_;

  // **** WriteBuffer specific Getters and Methods
  ByteData get bd => (_isClosed) ? null : wb.bd;

  // **** WriteBuffer specific Getters and Methods

  int get wIndex => wIndex_;

  set wIndex(int n) {
    if (wIndex_ <= rIndex_ || wIndex_ > wb.lengthInBytes)
      throw new RangeError.range(wIndex_, rIndex_, wb.lengthInBytes);
    wIndex_ = n;
  }

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int wSkip(int n) {
    final v = wIndex_ + n;
    if (v <= rIndex_ || v >= wb.lengthInBytes)
      throw new RangeError.range(v, 0, wb.lengthInBytes);
    return wIndex_ = v;
  }

  /// Returns the number of bytes left in the current buffer ([wb]).
  int get wRemaining => wb.lengthInBytes - wIndex_;

  bool hasRemaining(int n) => (wIndex_ + n) <= wb.lengthInBytes;

  int get start => wb.offsetInBytes;

  int get end => wb.lengthInBytes;

  bool get isWritable => wIndex_ < wb.lengthInBytes;

  bool get isEmpty => wIndex_ == start;

  bool get isNotEmpty => !isEmpty;

  /// Returns _true_ if _this_ is no longer writable.
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  Uint8List close() {
    if (hadTrailingBytes) hadTrailingZeros = checkAllZeros(wIndex_, wb.lengthInBytes);
    final bytes = wb.bd.buffer.asUint8List(0, wIndex_);
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

  // **** Aids to pretty printing - these may go away.

  /// The current readIndex as a string.
  String get _www => 'W@${wIndex_.toString().padLeft(5, '0')}';
  String get www => _www;

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www';

  /// The end of reading something.
  String get wee => '< $_www';

  String get pad => ''.padRight('$_www'.length);

  /// Ensures that [wb] is at least [wIndex] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  bool ensureRemaining(int remaining) => ensureCapacity(wIndex_ + remaining);

  /// Ensures that [wb] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  bool ensureCapacity(int capacity) => (capacity > wb.lengthInBytes) ? wb.grow() : false;

  void int8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow(1);
    wb.setInt8(wIndex_, value);
    wIndex_++;
  }

  /// Writes a byte (Uint8) value to _this_.
  void uint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    wb.setUint8(wIndex_, value);
    wIndex_++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void uint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    wb.setUint16(wIndex_, value);
    wIndex_ += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void uint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    wb.setUint32(wIndex_, value);
    wIndex_ += 4;
  }

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void uint64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out of range: $value');
    _maybeGrow(8);
    wb.setUint64(wIndex_, value);
    wIndex_ += 8;
  }

  /// Writes [bytes] to _this_.
  void writeBD(Uint8List bytes) {
    _maybeGrow(bytes.lengthInBytes);
    for (var i = 0, j = wIndex_; i < wb.length; i++, j++) wb.setUint8(j, bytes[i]);
    wIndex_ += bytes.lengthInBytes;
  }

  /// Writes [data] to _this_.
  void write(TypedData data) {
    final bytes = data.buffer.asUint8List();
    _maybeGrow(bytes.lengthInBytes);
    for (var i = 0, j = wIndex_; i < wb.length; i++, j++) wb.setUint8(j, bytes[i]);
    wIndex_ += bytes.lengthInBytes;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (wb.getUint8(i) != 0) return false;
    return true;
  }

  /// Writes [count] zeros into _this_.
  bool writeZeros(int count) {
    _maybeGrow(count);
    for (var i = 0, j = wIndex_; i < count; i++, j++) wb.setUint8(j, 0);
    wIndex_ += count;
    return true;
  }

  /// Write a DICOM Tag Code to _this_.
  void code(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(wIndex_.isEven && hasRemaining(4));
    _maybeGrow(4);
    wb..setUint16(wIndex_, code >> 16)..setUint16(wIndex_ + 2, code & 0xFFFF);
    wIndex_ += 4;
  }

  @override
  String toString() => '$runtimeType(${wb.length})[$wIndex_] maxLength: ${wb.limit}';

  /// Grow the buffer if the [wIndex] is at, or beyond, the end of the current buffer.
  bool _maybeGrow([int size = 1]) =>
      ((wIndex_ + size) < wb.lengthInBytes) ? false : wb.grow(wIndex_ + size);

  static const int kDefaultLength = 4096;
}
