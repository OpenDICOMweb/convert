// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

// ignore_for_file: non_constant_identifier_names

abstract class WriteBufferMixin {
  ByteData get bd;
  Uint8List get bytes;
  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  int get limit;
  bool growBuffer([int capacity]);
  bool checkAllZeros(int offset, int length);
  Endian get endian;

  // **** WriteBuffer specific Getters and Methods
  //Urgent: move to
//  ByteData get bd => (_isClosed) ? null : bd;

  // **** WriteBuffer specific Getters and Methods

  set wIndex_(int n) {
    if (wIndex_ <= rIndex_ || wIndex_ > bd.lengthInBytes)
      throw new RangeError.range(wIndex_, rIndex_, bd.lengthInBytes);
    wIndex_ = n;
  }

  int get wIndex => wIndex_;
  set wIndex(int n) => wIndex = n;

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int wSkip(int n) {
    final v = wIndex_ + n;
    if (v <= rIndex_ || v >= bd.lengthInBytes)
      throw new RangeError.range(v, 0, bd.lengthInBytes);
    return wIndex_ = v;
  }

  /// Returns the number of writeable bytes left in _this_.
  int get wRemaining => bd.lengthInBytes - wIndex_;

  bool wHasRemaining(int n) => (wIndex_ + n) <= bd.lengthInBytes;

  ByteData get contentUnwritten =>
      bd.buffer.asByteData(wIndex_, bd.lengthInBytes - wIndex_);

  int get start => bd.offsetInBytes;

  int get end => bd.lengthInBytes;

  bool get isWritable => wIndex_ < bd.lengthInBytes;

  bool get isEmpty => wIndex_ == start;
  bool get isNotEmpty => !isEmpty;

  /// Ensures that [bd] is at least [wIndex] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  bool ensureRemaining(int remaining) => ensureCapacity(wIndex_ + remaining);

  /// Ensures that [bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  bool ensureCapacity(int capacity) =>
      (capacity > bd.lengthInBytes) ? growBuffer() : false;

  void writeInt8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow(1);
    bd.setInt8(wIndex_, value);
    wIndex_++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void writeInt16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    bd.setInt16(wIndex_, value, endian);
    wIndex_ += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void writeInt32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    bd.setInt32(wIndex_, value, endian);
    wIndex_ += 4;
  }

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void writeInt64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out of range: $value');
    _maybeGrow(8);
    bd.setInt64(wIndex_, value, endian);
    wIndex_ += 8;
  }

  /// Writes a byte (Uint8) value to _this_.
  void writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    bd.setUint8(wIndex_, value);
    wIndex_++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    bd.setUint16(wIndex_, value, endian);
    wIndex_ += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    bd.setUint32(wIndex_, value, endian);
    wIndex_ += 4;
  }

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void writeUint64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out of range: $value');
    _maybeGrow(8);
    bd.setUint64(wIndex_, value, endian);
    wIndex_ += 8;
  }

  /// Writes [bytes] to _this_.
  void writeBD(Uint8List bytes) {
    _maybeGrow(bytes.lengthInBytes);
    for (var i = 0, j = wIndex_; i < bd.lengthInBytes; i++, j++) bd.setUint8(j, bytes[i]);
    wIndex_ += bytes.lengthInBytes;
  }

  /// Writes [data] to _this_.
  void write(TypedData data) {
    final bytes = data.buffer.asUint8List();
    _maybeGrow(bytes.lengthInBytes);
    for (var i = 0, j = wIndex_; i < bd.lengthInBytes; i++, j++) bd.setUint8(j, bytes[i]);
    wIndex_ += bytes.lengthInBytes;
  }

  /// Writes [count] zeros into _this_.
  bool writeZeros(int count) {
    _maybeGrow(count);
    for (var i = 0, j = wIndex_; i < count; i++, j++) bd.setUint8(j, 0);
    wIndex_ += count;
    return true;
  }

  ByteData bdView([int start = 0, int length]) {
    length ??= bd.lengthInBytes;
    final offset = _getOffset(start, length);
    return bd.buffer.asByteData(offset, length);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asUint8List(offset, length ?? bd.lengthInBytes - offset);
  }

  int _getOffset(int start, int length) {
    final offset = bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= bd.lengthInBytes);
    assert(offset + length <= bd.lengthInBytes,
        'offset($offset) + length($length) > bd.lengthInBytes($bd.lengthInBytes)');
    return offset;
  }

  @override
  String toString() => '$runtimeType(${bd.lengthInBytes})[$wIndex_] '
      'maxLength: $limit';

  /// Grow the buffer if the [wIndex] is at, or beyond, the end of the current buffer.
  bool _maybeGrow([int size = 1]) =>
      ((wIndex_ + size) < bd.lengthInBytes) ? false : growBuffer(wIndex_ + size);

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    final bytes = bd.buffer.asByteData(0, wIndex_);
    _isClosed = true;
    return bytes;
  }

  void get reset {
    rIndex_ = 0;
    wIndex_ = 0;
    _isClosed = false;
  }

  static const int kDefaultLength = 4096;
}
