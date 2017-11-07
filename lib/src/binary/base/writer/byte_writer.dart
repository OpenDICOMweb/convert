// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/byte_list.dart';

class ByteWriter extends ByteList {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  final int maxLength;
  int _wIndex = 0;

  factory ByteWriter([int length = ByteList.kDefaultLength, int maxLength = k1GB]) {
    final bd = new ByteData(ByteList.isValidBufferLength(length, maxLength));
    return new ByteWriter._(bd, maxLength);
  }

  ByteWriter._(ByteData bd, [this.maxLength = k1GB]) : super(bd);

  // **** WriteBuffer specific Getters and Methods

  int operator +(int n) => _indexAdd(n);
  int operator -(int n) => _indexAdd(-n);

  int get index => _wIndex;
  set index(int n) => _setIndexTo(n);

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int _indexAdd(int n) {
    assert(_hasRemaining(n));
    final index = _wIndex + n;
    return _setIndexTo(index);
  }

  int _setIndexTo(int index) {
    if (index < 0 || index > bd.lengthInBytes)
      throw new RangeError.range(index, 0, bd.lengthInBytes);
    return _wIndex = index;
  }

  @override
  ByteData get bd => (_isClosed) ? null : super.bd;

  int get wIndex => _wIndex;

  /// Returns the number of bytes left in the current buffer ([bd]).
  int get remaining => bd.lengthInBytes - _wIndex;
  bool hasRemaining(int n) => _hasRemaining(n);
  bool _hasRemaining(int n) => (_wIndex + n) <= bd.lengthInBytes;

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;

  bool get isWritable => _isWritable;
  bool get _isWritable => _wIndex < bd.lengthInBytes;

  @override
  bool get isEmpty => _wIndex == start;
  @override
  bool get isNotEmpty => !isEmpty;

  int move(int n) {
    final v = _wIndex + n;
    if (v < 0 || v >= bd.lengthInBytes)
      throw new RangeError.range(v, 0, bd.lengthInBytes);
    return _wIndex = v;
  }

/*
  void _checkRange(int v) {
    if (v < 0 || v >= bd.lengthInBytes)
    	throw new RangeError.range(v, 0, bd.lengthInBytes);
  }
*/
  void int8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow();
    setInt8(_wIndex, value);
    _wIndex++;
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
    assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(8);
    setUint64(_wIndex, value);
    _wIndex += 8;
  }

  /// Writes [bytes] to the output [bd].
  void bytes(Uint8List bytes) => _writeBytes(bytes);

  void _writeBytes(Uint8List bytes) {
    final length = bytes.lengthInBytes;
    _maybeGrow(length);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, bytes[i]);
    _wIndex = _wIndex + length;
  }

  /// Writes [bytes], which contains Code Units to the output [bd],
  /// ensuring that an even number of bytes are written, by adding
  /// a padding character if necessary.
  void _writeVF(Uint8List bytes, [int padChar = kSpace]) {
    _writeBytes(bytes);
    if (bytes.length.isOdd) {
      setUint8(_wIndex, padChar);
      _wIndex++;
    }
  }

  /// Writes an [ASCII] [String] to the output [bd].
  void ascii(String s, [int offset = 0, int limit, int padChar = kSpace]) =>
      _writeVF(ASCII.encode(s), padChar);

  /// Writes an [UTF8] [String] to the output [bd].
  void utf8(String s, [int offset = 0, int limit]) => _writeVF(UTF8.encode(s), kSpace);

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
    assert(offset + length >= offset && (offset + length) <= bd.lengthInBytes);
    return offset;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros;

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  Uint8List close() {
    if (hadTrailingBytes) {
      hadTrailingZeros = _checkAllZeros(_wIndex, bd.lengthInBytes);
      log.debug('Trailing Bytes($remaining) All Zeros: $hadTrailingZeros');
    }

    final bytes = uint8View(0, _wIndex);
    _isClosed = true;
    return bytes;
  }

  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  // **** Aids to pretty printing - these may go away.

  /// The current readIndex as a string.
  String get _www => 'W@$_wIndex';

  String get www => _www;

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www';

  /// The end of reading something.
  String get wee => '< $_www';

  void debug(String msg, [int level]) => log.debug(msg, level);

  /// Ensures that [bd] is at least [index] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  void ensureRemaining(int index, int remaining) => ensureCapacity(index + remaining);

  /// Ensures that [bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) => (capacity > bd.lengthInBytes) ? grow() : null;

  @override
  String toString() => '$runtimeType($length)[$_wIndex] maxLength: $maxLength';

  // Internal methods

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  void _maybeGrow([int size = 1]) {
    //   log.debug('_wIndex: $_wIndex');
//    log.debug('lengthInBytes: ${bd.lengthInBytes}');
    if (_wIndex + size >= bd.lengthInBytes) grow();
  }
}
