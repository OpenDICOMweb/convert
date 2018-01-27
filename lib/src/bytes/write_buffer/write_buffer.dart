// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';
import 'package:convert/src/bytes/buffer/buffer_base.dart';
import 'package:convert/src/bytes/write_buffer/write_buffer_mixin.dart.old';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

class WriteBuffer extends BufferBase with WriteBufferMixin {
  @override
  final GrowableBytes bytes;
  @override
  int rIndex_;
  @override
  int wIndex_;

  WriteBuffer(
      [int length = kDefaultLength,
      Endian endian = Endian.little,
      int limit = kDefaultLimit])
      : rIndex_ = 0,
        wIndex_ = 0,
        bytes = new GrowableBytes(length, endian, limit);

  WriteBuffer.from(WriteBuffer wb,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      int limit = kDefaultLimit])
      : rIndex_ = offset,
        wIndex_ = offset,
        bytes = new GrowableBytes.from(wb.bytes, offset, length, endian, limit);

  WriteBuffer.fromByteData(ByteData bd,
      [Endian endian = Endian.little, int limit = kDefaultLimit])
      : rIndex_ = 0,
        wIndex_ = bd.lengthInBytes,
        bytes = new GrowableBytes.fromTypedData(bd, endian, limit);

  WriteBuffer.fromUint8List(Uint8List uint8List,
      [Endian endian = Endian.little, int limit = kDefaultLimit])
      : rIndex_ = 0,
        wIndex_ = uint8List.lengthInBytes,
        bytes = new GrowableBytes.fromTypedData(uint8List, endian, limit);

  WriteBuffer._(int length, Endian endian, int limit)
      : rIndex_ = 0,
        wIndex_ = 0,
        bytes = new GrowableBytes(length, endian, limit);

  WriteBuffer._fromTD(TypedData td, Endian endian, int limit)
      : rIndex_ = 0,
        wIndex_ = td.lengthInBytes,
        bytes = new GrowableBytes.fromTypedData(td, endian, limit);

  // **** WriteBuffer specific Getters and Methods

  @override
  int get limit => bytes.limit;

  /// Returns the number of bytes left in the current _this_.
  int get remaining => wRemaining;

  @override
  bool get isEmpty => isNotWritable;

  bool hasRemaining(int n) => wHasRemaining(n);

/* Flush
  ByteData toByteData(int offset, int lengthInBytes) =>
      bd.buf.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bd.buf.asUint8List(bd.offsetInBytes + offset, lengthInBytes);
*/

  bool _isClosed;
  @override
  bool get isClosed => (_isClosed == null) ? false : true;

  bool _hadTrailingZeros;

  @override
  bool get hadTrailingZeros => _hadTrailingZeros ?? false;
  ByteData rClose() {
    final view = asByteData(0, rIndex_);
    if (isNotEmpty) {
      //  warn('End of Data with rIndex_($rIndex) != length(${view.lengthInBytes})');
      _hadTrailingZeros = checkAllZeros(rIndex_, wIndex_);
    }
    _isClosed = true;
    return view;
  }

  @override
  String toString() => '$runtimeType($length)[$wIndex_] maxLength: $limit';

  // Internal methods

  static const int kDefaultLength = 4096;
}

const int _k1GB = 1024 * 1024 * 1024;

class LoggingWriteBuffer extends WriteBuffer with WriterLogMixin {
  LoggingWriteBuffer(
      [int length = kDefaultLength,
      Endian endian = Endian.little,
      int limit = _k1GB])
      : super._(length, endian, limit);

  factory LoggingWriteBuffer.fromByteData(ByteData bd,
          [Endian endian = Endian.little, int limit = kDefaultLimit]) =>
      new LoggingWriteBuffer.fromTypedData(bd, endian, limit);

  factory LoggingWriteBuffer.fromBytes(Uint8List td,
          [Endian endian = Endian.little, int limit = kDefaultLimit]) =>
      new LoggingWriteBuffer.fromTypedData(td, endian, limit);

  LoggingWriteBuffer.fromTypedData(TypedData td, Endian endian, int limit)
      : super._fromTD(td, endian, limit);
}
