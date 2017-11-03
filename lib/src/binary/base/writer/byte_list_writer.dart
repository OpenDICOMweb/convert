// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/byte_list.dart';

class ByteListWriter extends ByteList implements TypedData {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
 @override ByteData bd;
  final int maxLength;
  final Endianness endian;
  int _wIndex = 0;


  ByteListWriter([int length = kDefaultLength, this.maxLength = k1GB,
	                 this.endian = kDefaultEndian])
      : this.bd = new ByteData(_isValidBufferLength(length, maxLength));

  factory ByteListWriter.view(ByteListWriter bd, [int start = 0, int end]) {
    if (start < 0 || start >= bd.lengthInBytes)
      throw new RangeError.index(start, bd);
    end ??= bd.lengthInBytes;
    if (end < 0 || end >= bd.lengthInBytes) throw new RangeError.index(end, bd);
    return new ByteListWriter._(
        bd.buffer.asByteData(bd.offsetInBytes + start, bd.offsetInBytes + end));
  }

  ByteListWriter._(this.bd , [this.maxLength = k1GB, this.endian = kDefaultEndian]);

 ByteData get asByteDataView => bd.buffer.asByteData(0, _wIndex);

 Uint8List get asUint8ListView => bd.buffer.asUint8List(0, _wIndex);

  int get endOfBD => bd.lengthInBytes;
  int get wIndex => _wIndex;
  bool get _isWritable => _wIndex < bd.lengthInBytes;
  bool get isWritable => _isWritable;

  int move(int n) {
    final v = _wIndex + n;
    _checkRange(v);
    _wIndex = v;
    return v;
  }

  void _checkRange(int v) {
    final max = bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  // The Reader
 int getUint8(int index) => bd.getInt8(index);

  // The Writers

 void setInt8(int index, int value) => bd.setInt8(index, value);
 void setUint8(int index, int value) => bd.setUint8(index, value);
 void setUint16(int index, int value) => bd.setUint16(index, value, endian);
 void setInt16(int index, int value) => bd.setInt16(index, value, endian);
 void setUint32(int index, int value) => bd.setUint32(index, value, endian);
 void setInt32(int index, int value) => bd.setInt32(index, value, endian);
 void setUint64(int index, int value) => bd.setUint64(index, value, endian);
 void setInt64(int index, int value) => bd.setInt64(index, value, endian);
 void setFloat32(int index, double value) => bd.setFloat32(index, value, endian);
 void setFloat64(int index, double value) => bd.setFloat64(index, value, endian);

  void writeInt8(int value) {
    assert(value >= -128 && value <= 127, 'Value out of range: $value');
    _maybeGrow();
    setInt8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a byte (Uint8) value to the output [bd].
  void writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    setUint8(_wIndex, value);
    _wIndex++;
  }

  /// Writes a 16-bit unsigned integer (Uint16) value to the output [bd].
  void writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    setUint16(_wIndex, value);
    _wIndex += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to the output [bd].
  void writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    setUint32(_wIndex, value);
    _wIndex += 4;
  }

 /// Writes a 64-bit unsigned integer (Uint32) value to the output [bd].
 void writeUint64(int value) {
	 assert(value >= 0 && value <= 0xFFFFFFFFFFFFFFFF, 'Value out if range: $value');
	 _maybeGrow(8);
	 setUint64(_wIndex, value);
	 _wIndex += 8;
 }

  /// Writes [bytes] to the output [bd].
  void writeBytes(Uint8List bytes) => _writeBytes(bytes);

  void _writeBytes(Uint8List bytes) {
    final length = bytes.length;
    _maybeGrow(length);
    for (var i = 0, j = _wIndex; i < length; i++, j++) setUint8(j, bytes[i]);
    _wIndex = _wIndex + length;
  }

  /// Writes [bytes], which contains Code Units to the output [bd],
  /// ensuring that an even number of bytes are written, by adding
  /// a padding character if necessary.
  void _writeStringBytes(Uint8List bytes, [int padChar = kSpace]) {
    _writeBytes(bytes);
    if (bytes.length.isOdd) {
      setUint8(_wIndex, padChar);
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
  void ensureRemaining(int index, int remaining) =>
      ensureCapacity(index + remaining);

  /// Ensures that [bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) =>
      (capacity > lengthInBytes) ? _grow() : null;

  // Internal methods

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  void _maybeGrow([int size = 1]) {
/*    print('_wIndex: $_wIndex');
    print('lengthInBytes: ${lengthInBytes}');*/
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
    print('start _grow: $lengthInBytes');
    final oldLength = lengthInBytes;
    var newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;

    _isValidBufferLength(newLength);
    if (newLength < oldLength) return;
    final newBuffer = new ByteData(newLength);
    for (var i = 0; i < oldLength; i++) newBuffer.setUint8(i, getUint8(i));
    bd = newBuffer;
    print('end _grow $lengthInBytes');
  }

  static const Endianness kDefaultEndian = Endianness.LITTLE_ENDIAN;
 static const int kDefaultLength = 1024;
 static const int kMinByteListLength = 768;
}


int _isValidBufferLength(int length, [int maxLength = k1GB]) {
  print('isValidlength: $length');
  RangeError.checkValidRange(1, length, maxLength);
  return length;
}

