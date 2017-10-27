// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:system/core.dart';

class ByteDataBuffer {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  ByteData _bd;
  final int maxLength;
  int _wIndex = 0;

  ByteDataBuffer([int length = defaultLength, this.maxLength = k1GB])
      : this._bd = new ByteData(_isValidBufferLength(length, maxLength));

  factory ByteDataBuffer.view(ByteDataBuffer bd, [int start = 0, int end]) {
    if (start < 0 || start >= bd.lengthInBytes)
      throw new RangeError.index(start, bd);
    if (end == null) end = bd.lengthInBytes;
    if (end < 0 || end >= bd.lengthInBytes) throw new RangeError.index(end, bd);
    return new ByteDataBuffer._(
        bd.buffer.asByteData(bd.offsetInBytes + start, bd.offsetInBytes + end));
  }

  ByteDataBuffer._(ByteData buffer, [this.maxLength = k1GB]) : this._bd = buffer;

  // TypedData interface.

  int get elementSizeInBytes => _bd.elementSizeInBytes;

  int get offsetInBytes => _bd.offsetInBytes;

  int get lengthInBytes => _bd.lengthInBytes;

  /// Returns the underlying [ByteBuffer].
  ///
  /// The returned buffer may be replaced by operations that change the [length]
  /// of this list.
  ///
  /// The buffer may be larger than [lengthInBytes] bytes, but never smaller.
  ByteData get bd => _bd;
  int get length => _bd.lengthInBytes;
  ByteBuffer get buffer => _bd.buffer;
  int get endOfBD => _bd.lengthInBytes;
  int get wIndex => _wIndex;
  bool get _isWritable => _wIndex < _bd.lengthInBytes;
  bool get isWriteable => _isWritable;

  void skip(int n) {
    int v = _wIndex + n;
    _checkRange(v);
    _wIndex = v;
  }

  void _checkRange(int v) {
    int max = _bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  // The Writers

  //int readInt8() => _bd.getInt8(_());

  void writeInt8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow();
    _bd.setInt8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a byte (Uint8) value to the output [bd].
  void writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    _bd.setUint8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to the output [bd].
  void writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    _bd.setUint16(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to the output [bd].
  void writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    _bd.setUint32(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 4;
  }

  /// Writes [bytes] to the output [bd].
  void writeBytes(Uint8List bytes) => _writeBytes(bytes);

  void _writeBytes(Uint8List bytes) {
    int length = bytes.length;
    _maybeGrow(length);
    for (int i = 0, j = _wIndex; i < length; i++, j++) _bd.setUint8(j, bytes[i]);
    _wIndex = _wIndex + length;
  }

  /// Writes [bytes], which contains Code Units to the output [bd],
  /// ensuring that an even number of bytes are written, by adding
  /// a padding character if necessary.
  void _writeStringBytes(Uint8List bytes, [int padChar = kSpace]) {
    _writeBytes(bytes);
    if (bytes.length.isOdd) {
      _bd.setUint8(_wIndex, padChar);
      _wIndex++;
    }
  }

  /// Writes an [ASCII] [String] to the output [bd].
  void writeAsciiString(String s,
          [int offset = 0, int limit, int padChar = kSpace]) =>
      _writeStringBytes(ASCII.encode(s), padChar);

  /// Writes an [UTF8] [String] to the output [bd].
  void writeUtf8String(String s, [int offset = 0, int limit]) =>
      _writeStringBytes(UTF8.encode(s), kSpace);

  /// Ensures that [_bd] is at least [index] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  void ensureRemaining(int index, int remaining) =>
      ensureCapacity(index + remaining);

  /// Ensures that [_bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) =>
      (capacity > _bd.lengthInBytes) ? _grow() : null;

  // Internal methods

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  void _maybeGrow([int size = 1]) {
/*    print('_wIndex: $_wIndex');
    print('lengthInBytes: ${_bd.lengthInBytes}');*/
    if (_wIndex + size >= _bd.lengthInBytes) _grow();
  }

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [capacity] is null the new buffer will be twice the size of the
  /// current buffer. If [capacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  void _grow([int capacity]) {
    print('start _grow: ${_bd.lengthInBytes}');
    int oldLength = _bd.lengthInBytes;
    int newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;

    _isValidBufferLength(newLength);
    if (newLength < oldLength) return;
    var newBuffer = new ByteData(newLength);
    for (int i = 0; i < oldLength; i++) newBuffer.setUint8(i, _bd.getUint8(i));
    _bd = newBuffer;
    print('end _grow ${_bd.lengthInBytes}');
  }
}

const int defaultLength = 16;
const int k1GB = 1024 * 1024 * 1024;

int _isValidBufferLength(int length, [int maxLength = k1GB]) {
  print('isValidlength: $length');
  RangeError.checkValidRange(1, length, maxLength);
  return length;
}

