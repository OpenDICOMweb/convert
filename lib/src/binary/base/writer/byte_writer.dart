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
  ByteData _bd;
  final int maxLength;
  final Endianness endian;
  int _wIndex = 0;

  factory ByteWriter(
      [int length = kDefaultLength,
      int maxLength = k1GB,
      Endianness endian = kDefaultEndian]) {
    final bd = new ByteData(_isValidBufferLength(length, maxLength));
    return new ByteWriter._(bd, maxLength, endian);
  }

/* Flush if not needed
  factory ByteListWriter.view(ByteListWriter bd, [int start = 0, int end]) {
  	RangeError.checkValidRange(start, end, bd.lengthInBytes);
    return new ByteListWriter._(
        bd.buffer.asByteData(bd.offsetInBytes + start, bd.offsetInBytes + end));
  }
*/

  ByteWriter._(this._bd, [this.maxLength = k1GB, this.endian = kDefaultEndian])
      : super(_bd);

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
    if (index < 0 || index > _bd.lengthInBytes)
      throw new RangeError.range(index, 0, _bd.lengthInBytes);
    return _wIndex = index;
  }

  @override
  ByteData get bd => (_isClosed) ? null : _bd;

  int get wIndex => _wIndex;

  /// Returns the number of bytes left in the current buffer ([bd]).
  int get remaining => _bd.lengthInBytes - _wIndex;
  bool hasRemaining(int n) => _hasRemaining(n);
  bool _hasRemaining(int n) => (_wIndex + n) <= _bd.lengthInBytes;

  int get start => _bd.offsetInBytes;
  int get end => _bd.lengthInBytes;

  bool get isWritable => _isWritable;
  bool get _isWritable => _wIndex < _bd.lengthInBytes;

  @override
  bool get isEmpty => _wIndex == start;
  @override
  bool get isNotEmpty => !isEmpty;

  int move(int n) {
    final v = _wIndex + n;
    if (v < 0 || v >= _bd.lengthInBytes)
      throw new RangeError.range(v, 0, _bd.lengthInBytes);
    return _wIndex = v;
  }

/*
  void _checkRange(int v) {
    if (v < 0 || v >= _bd.lengthInBytes)
    	throw new RangeError.range(v, 0, _bd.lengthInBytes);
  }
*/

  // The Reader
  int getUint8(int index) => _bd.getInt8(index);

  // The Writers
  void setInt8(int index, int value) => _bd.setInt8(index, value);
  void setUint8(int index, int value) => _bd.setUint8(index, value);
  void setUint16(int index, int value) => _bd.setUint16(index, value, endian);
  void setInt16(int index, int value) => _bd.setInt16(index, value, endian);
  void setUint32(int index, int value) => _bd.setUint32(index, value, endian);
  void setInt32(int index, int value) => _bd.setInt32(index, value, endian);
  void setUint64(int index, int value) => _bd.setUint64(index, value, endian);
  void setInt64(int index, int value) => _bd.setInt64(index, value, endian);
  void setFloat32(int index, double value) => _bd.setFloat32(index, value, endian);
  void setFloat64(int index, double value) => _bd.setFloat64(index, value, endian);

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
    final length = bytes.length;
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
    return _bd.buffer.asByteData(start, length ?? _bd.lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return _bd.buffer.asUint8List(offset, length ?? _bd.lengthInBytes - offset);
  }

  int _getOffset(int start, int length) {
    final offset = _bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= _bd.lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= _bd.lengthInBytes);
    return offset;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros;

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  Uint8List close() {
    _isClosed = true;
/*	  if (hadTrailingBytes) {
		  hadTrailingZeros = checkAllZeros(_rIndex, _bd.lengthInBytes);
		  log.debug('Trailing Bytes($remaining) All Zeros: $hadTrailingZeros');
	  }*/

    return uint8View(0, _wIndex);
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
  void ensureCapacity(int capacity) => (capacity > lengthInBytes) ? _grow() : null;

  // Internal methods

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  void _maybeGrow([int size = 1]) {
/*    log.debug('_wIndex: $_wIndex');
    log.debug('lengthInBytes: ${lengthInBytes}');*/
    if (_wIndex + size >= lengthInBytes) _grow();
  }

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [capacity] is null the new buffer will be twice the size of the
  /// current buffer. If [capacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  void _grow([int capacity]) {
    log.debug('start _grow: $lengthInBytes');
    final oldLength = lengthInBytes;
    var newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;

    _isValidBufferLength(newLength);
    if (newLength < oldLength) return;
    final newBuffer = new ByteData(newLength);
    for (var i = 0; i < oldLength; i++) newBuffer.setUint8(i, getUint8(i));
    _bd = newBuffer;
    log.debug('end _grow $lengthInBytes');
  }

  static const Endianness kDefaultEndian = Endianness.LITTLE_ENDIAN;
  static const int kDefaultLength = 1024;
  static const int kMinByteListLength = 768;
}

int _isValidBufferLength(int length, [int maxLength = k1GB]) {
  log.debug('isValidlength: $length');
  RangeError.checkValidRange(1, length, maxLength);
  return length;
}
