// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';
import 'package:convert/src/bytes/buffer/buffer_base.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

class ReadBuffer extends BufferBase {
  @override
  final Bytes bytes;

  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  @override
  int rIndex_;
  @override
  int wIndex_;

  ReadBuffer(ByteData bd, [Endian endian = Endian.little])
      : rIndex_ = 0,
        wIndex_ = bd.lengthInBytes,
        bytes = new Bytes.fromByteData(bd, endian);

  ReadBuffer.from(ReadBuffer rb,
      [int offset = 0, int length, Endian endian = Endian.little])
      : rIndex_ = offset,
        wIndex_ = offset + (length ?? rb.lengthInBytes),
        bytes = new Bytes.from(rb.bytes, offset, length, endian);

  ReadBuffer.fromUint8List(Uint8List uint8List, [Endian endian = Endian.little])
      : rIndex_ = 0,
        wIndex_ = uint8List.lengthInBytes,
        bytes = new Bytes.fromUint8List(uint8List, endian);

  ReadBuffer.fromList(List<int> list, [Endian endian = Endian.little])
      : rIndex_ = 0,
        wIndex_ = list.length,
        bytes = new Bytes.fromUint8List(new Uint8List.fromList(list), endian);

  ReadBuffer._fromTypedData(TypedData td, Endian endian)
      : rIndex_ = 0,
        wIndex_ = td.lengthInBytes,
        bytes = new Bytes.fromByteData(td, endian);

  // **** ReadBuffer specific Getters and Methods

  int get index => rIndex_;

  int get remaining => rRemaining;

  @override
  bool get isEmpty => isNotReadable;

  bool hasRemaining(int n) => rHasRemaining(n);

  int getInt8() => bytes.getInt8(rIndex_);

  int readInt8() {
    final v = bytes.getInt8(rIndex_);
    rIndex_++;
    return v;
  }

  int getInt16() => bytes.getInt16(rIndex_);

  int readInt16() {
    final v = bytes.getInt16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  int getInt32() => bytes.getInt32(rIndex_);

  int readInt32() {
    final v = bytes.getInt32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int getInt64() => bytes.getInt64(rIndex_);

  int readInt64() {
    final v = bytes.getInt64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  int getUint8() => bytes.getUint8(rIndex_);

  int readUint8() {
    final v = bytes.getUint8(rIndex_);
    rIndex_++;
    return v;
  }

  int getUint16() => bytes.getUint16(rIndex_);

  int readUint16() {
    final v = bytes.getUint16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  int getUint32() => bytes.getUint32(rIndex_);

  int readUint32() {
    final v = bytes.getUint32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int getUint64() => bytes.getUint64(rIndex_);

  int readUint64() {
    final v = bytes.getUint64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [rIndex_].
  int peekCode() {
    assert(rIndex_.isEven && hasRemaining(4), '@$rIndex_ : $remaining');
    final group = bytes.getUint16(rIndex_);
    final elt = bytes.getUint16(rIndex_ + 2);
    return (group << 16) + elt;
  }

  int getCode(int start) => peekCode();

  int readCode() {
    final code = peekCode();
    rIndex_ += 4;
    return code;
  }

  bool getUint32AndCompare(int target) {
    final delimiter = bytes.getUint32(rIndex_);
    final v = target == delimiter;
    return v;
  }

  ByteData bdView([int start = 0, int end]) {
    end ??= rIndex_;
    final length = end - start;
    final offset = _getOffset(start, length);
    return bytes.asByteData(start, length ?? lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bytes.asUint8List(offset, length ?? lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(rIndex_, length);

  int _getOffset(int start, int length) {
    final offset = bytes.offsetInBytes + start;
    assert(offset >= 0 && offset <= lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= lengthInBytes);
    return offset;
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bytes.buffer.asByteData(bytes.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bytes.buffer.asUint8List(bytes.offsetInBytes + offset, lengthInBytes);

  void checkRange(int v) {
    final max = lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  bool _isClosed = false;
  bool get isClosed => _isClosed;

  @override
  ByteData get bd => (isClosed) ? null : bytes.bd;

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (isClosed) ? isNotEmpty : false;
  bool _hadTrailingZeros;
  bool get hadTrailingZeros => _hadTrailingZeros ?? false;

  void get reset {
    rIndex_ = 0;
    wIndex_ = 0;
    _isClosed = false;
    _hadTrailingZeros = false;
  }
}

class LoggingReadBuffer extends ReadBuffer {
  factory LoggingReadBuffer(ByteData bd,
          [int offset = 0, int length, Endian endian = Endian.little]) =>
      new LoggingReadBuffer._(bd, endian);

  factory LoggingReadBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = Endian.little]) {
    final bd = bytes.buffer.asByteData(offset, length);
    return new LoggingReadBuffer._(bd, endian);
  }

  LoggingReadBuffer._(TypedData td, Endian endian)
      : super._fromTypedData(td.buffer.asByteData(), endian);

  /// The current readIndex as a string.
  String get _rrr => 'R@${rIndex_.toString().padLeft(5, '0')}';
  String get rrr => _rrr;

  /// The beginning of reading something.
  String get rbb => '> $_rrr';

  /// In the middle of reading something.
  String get rmm => '| $_rrr';

  /// The end of reading something.
  String get ree => '< $_rrr';

  String get pad => ''.padRight('$_rrr'.length);

  void warn(Object msg) => print('** Warning: $msg $_rrr');

  void error(Object msg) => throw new Exception('**** Error: $msg $_rrr');
}
