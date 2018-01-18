// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/byte_list/write_buffer_mixin.dart';

class WriteBuffer extends ByteListWritable with WriteBufferMixin {
  int _wIndex;

  WriteBuffer([int length = kDefaultLength])
      : _wIndex = 0,
        super.internal(length, k1GB);

  WriteBuffer.fromByteData(ByteData bd)
      : _wIndex = 0,
        super.fromByteData(bd);

  WriteBuffer.fromUint8List(Uint8List bytes)
      : _wIndex = 0,
        super.fromUint8List(bytes);

  // **** WriteBuffer specific Getters and Methods

  @override
  ByteData get bd => (_isClosed) ? null : super.bd;

  void int8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow(1);
    setInt8(_wIndex, value);
    _wIndex++;
  }

  void code(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(_wIndex.isEven && hasRemaining(4));
    _maybeGrow(4);
    setUint16(wIndex, code >> 16);
    setUint16(wIndex + 2, code & 0xFFFF);
    _wIndex += 4;
  }

  /// Writes a byte (Uint8) value to the output [bd].
  void uint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    setUint8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to the output [bd].
  void uint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    setUint16(_wIndex, value);
    _wIndex += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to the output [bd].
  void uint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    setUint32(_wIndex, value);
    _wIndex += 4;
  }

  /// Writes a 64-bit unsigned integer (Uint32) value to the output [bd].
  void uint64(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out of range: $value');
    _maybeGrow(8);
    setUint64(_wIndex, value);
    _wIndex += 8;
  }

  /// Writes [bytes] to the output [bd].
  bool writeZeros(int length) {
    _maybeGrow(length);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, 0);
    _wIndex = _wIndex + length;
    return true;
  }

  /// Writes [bytes] to the output [bd].
  void write(Uint8List bytes) => _writeBytes(bytes);

  void _writeBytes(Uint8List bytes) {
    final length = bytes.lengthInBytes;
    _maybeGrow(length);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, bytes[i]);
    _wIndex = _wIndex + length;
  }

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

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros = false;

  void get reset {
    _wIndex = 0;
    _isClosed = false;
    hadTrailingZeros = false;
  }

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  Uint8List close() {
    if (hadTrailingBytes) {
      hadTrailingZeros = _checkAllZeros(_wIndex, bd.lengthInBytes);
//      log.debug('Trailing Bytes($remaining) All Zeros: $hadTrailingZeros');
    }

    final bytes = uint8View(0, _wIndex);
    _isClosed = true;
    return bytes;
  }

  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  /// Ensures that [bd] is at least [wIndex] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  void ensureRemaining(int wIndex, int remaining) => ensureCapacity(wIndex + remaining);

  /// Ensures that [bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) => (capacity > bd.lengthInBytes) ? grow() : null;

  @override
  String toString() => '$runtimeType($length)[$_wIndex] maxLength: $maxLength';

  // Internal methods

  /// Grow the buffer if the wIndex is at, or beyond, the end of the current buffer.
  bool _maybeGrow([int size = 1]) =>
      ((_wIndex + size) < bd.lengthInBytes) ? false : grow(_wIndex + size);

  static const int kDefaultLength = 4096;

  static WriteBuffer from(WriteBuffer wb, [int offset = 0, int length]) =>
      new WriteBuffer.fromByteData(wb.bd.buffer.asByteData(offset, length));
}
