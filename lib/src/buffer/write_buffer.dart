// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/buffer/mixins/log_mixins.dart';

class WriteBuffer extends GrowableByteList {
  int _rIndex;
  int _wIndex;

  WriteBuffer(
      [int length = kDefaultLength,
      int limit = kDefaultLimit,
      Endian endian = Endian.little])
      : _rIndex = 0,
        _wIndex = 0,
        super(length ?? kDefaultLength, limit, endian);

  WriteBuffer.fromByteData(ByteData bd)
      : _rIndex = 0,
        _wIndex = 0,
        super.fromByteData(bd);

  WriteBuffer.fromUint8List(Uint8List bytes)
      : _rIndex = 0,
        _wIndex = 0,
        super.fromUint8List(bytes);

  WriteBuffer._(int length, int limit)
      : _rIndex = 0,
        _wIndex = 0,
        super.fromByteData(new ByteData(length ?? limit));

  // **** WriteBuffer specific Getters and Methods

  @override
  ByteData get bd => (_isClosed) ? null : super.bd;

  // **** WriteBuffer specific Getters and Methods

  int get wIndex => _wIndex;

  set wIndex(int n) {
    if (_wIndex <= _rIndex || _wIndex > bd.lengthInBytes)
      throw new RangeError.range(_wIndex, _rIndex, bd.lengthInBytes);
    _wIndex = n;
  }

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int wSkip(int n) {
    final v = _wIndex + n;
    if (v <= _rIndex || v >= bd.lengthInBytes)
      throw new RangeError.range(v, 0, bd.lengthInBytes);
    return _wIndex = v;
  }

  /// Returns the number of bytes left in the current buffer ([bd]).
  int get remaining => bd.lengthInBytes - _wIndex;

  bool hasRemaining(int n) => (_wIndex + n) <= bd.lengthInBytes;

  int get start => bd.offsetInBytes;

  int get end => bd.lengthInBytes;

  bool get isWritable => _wIndex < bd.lengthInBytes;

  @override
  bool get isEmpty => _wIndex == start;

  @override
  bool get isNotEmpty => !isEmpty;

  /// Returns _true_ if _this_ is no longer writable.
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  Uint8List close() {
    if (hadTrailingBytes) hadTrailingZeros = checkAllZeros(_wIndex, bd.lengthInBytes);
    final bytes = uint8View(0, _wIndex);
    _isClosed = true;
    return bytes;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros = false;

  void get reset {
    _rIndex = 0;
    _wIndex = 0;
    _isClosed = false;
    hadTrailingZeros = false;
  }

  // **** Aids to pretty printing - these may go away.

  /// The current readIndex as a string.
  String get _www => 'W@${_wIndex.toString().padLeft(5, '0')}';
  String get www => _www;

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www';

  /// The end of reading something.
  String get wee => '< $_www';

  String get pad => ''.padRight('$_www'.length);

  /// Ensures that [bd] is at least [wIndex] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  bool ensureRemaining(int remaining) => ensureCapacity(_wIndex + remaining);

  /// Ensures that [bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  bool ensureCapacity(int capacity) => (capacity > bd.lengthInBytes) ? grow() : false;

  void int8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow(1);
    setInt8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a byte (Uint8) value to _this_.
  void uint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    setUint8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to _this_.
  void uint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    setUint16(_wIndex, value);
    _wIndex += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to _this_.
  void uint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    setUint32(_wIndex, value);
    _wIndex += 4;
  }

  /// Writes a 64-bit unsigned integer (Uint32) value to _this_.
  void uint64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out of range: $value');
    _maybeGrow(8);
    setUint64(_wIndex, value);
    _wIndex += 8;
  }

  /// Writes [bytes] to _this_.
  void writeBD(Uint8List bytes) {
    _maybeGrow(bytes.lengthInBytes);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, bytes[i]);
    _wIndex += bytes.lengthInBytes;
  }

  /// Writes [data] to _this_.
  void write(TypedData data) {
    final bytes = data.buffer.asUint8List();
    _maybeGrow(bytes.lengthInBytes);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, bytes[i]);
    _wIndex += bytes.lengthInBytes;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (getUint8(i) != 0) return false;
    return true;
  }

  /// Writes [bytes] to _this_.
  bool writeZeros(int length) {
    _maybeGrow(length);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, 0);
    _wIndex += length;
    return true;
  }

  /// Write a DICOM Tag Code to _this_.
  void code(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(_wIndex.isEven && hasRemaining(4));
    _maybeGrow(4);
    setUint16(wIndex, code >> 16);
    setUint16(wIndex + 2, code & 0xFFFF);
    _wIndex += 4;
  }

/* Flush
  ByteData toByteData(int offset, int lengthInBytes) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, lengthInBytes);
*/

  ByteData bdView([int start = 0, int end]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asByteData(start, length ?? bd.lengthInBytes - offset);
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

  void warn(Object msg) => print('** Warning: $msg $_www');

  void error(Object msg) => throw new Exception('**** Error: $msg $_www');

  @override
  String toString() => '$runtimeType($length)[$_wIndex] maxLength: $limit';

  // Internal methods

  /// Grow the buffer if the [wIndex] is at, or beyond, the end of the current buffer.
  bool _maybeGrow([int size = 1]) =>
      ((_wIndex + size) < bd.lengthInBytes) ? false : grow(_wIndex + size);

  static const int kDefaultLength = 4096;

  static WriteBuffer from(WriteBuffer wb, [int offset = 0, int length]) =>
      new WriteBuffer.fromByteData(wb.bd.buffer.asByteData(offset, length));
}

class LoggingWriteBuffer extends WriteBuffer with WriterLogMixin {
  LoggingWriteBuffer([int length = kDefaultLength, int limit = k1GB])
      : super._(length, limit);

  LoggingWriteBuffer.fromByteData(ByteData bd) : super.fromByteData(bd);

  LoggingWriteBuffer.fromUint8List(Uint8List bytes) : super.fromUint8List(bytes);
}
