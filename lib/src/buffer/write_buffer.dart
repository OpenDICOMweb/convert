// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/buffer/buffer_base.dart';
import 'package:convert/src/buffer/mixins/log_mixins.dart';
import 'package:convert/src/buffer/mixins/write_buffer_mixin.dart';
import 'package:convert/src/byte_list/byte_list.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

class WriteBuffer extends BufferBase with WriteBufferMixin {
  @override
  final GrowableByteList bList;
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
        bList = new GrowableByteList(length, endian, limit);

  WriteBuffer.from(WriteBuffer wb,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      int limit = kDefaultLimit])
      : rIndex_ = offset,
        wIndex_ = offset,
        bList = new GrowableByteList.fromTypedData(
            wb.bd, offset, length, endian, limit);

  WriteBuffer.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      int limit = kDefaultLimit])
      : rIndex_ = offset,
        wIndex_ = offset,
        bList = new GrowableByteList.fromTypedData(
            bd, offset, length, endian, limit);

  WriteBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      Endian endian = Endian.little,
      int limit = kDefaultLimit])
      : rIndex_ = offset,
        wIndex_ = offset,
        bList = new GrowableByteList.fromTypedData(
            bytes, offset, length, endian, limit);

  WriteBuffer._(int length, Endian endian, int limit)
      : rIndex_ = 0,
        wIndex_ = 0,
        bList = new GrowableByteList(length, endian, limit);

  WriteBuffer._fromTD(TypedData td,
      int offset,
        int length,
        Endian endian,
        int limit)
      : rIndex_ = offset,
        wIndex_ = length ?? td.lengthInBytes,
        bList = new GrowableByteList.fromTypedData(
            td, offset, length, endian, limit);

  // **** WriteBuffer specific Getters and Methods

  @override
  int get limit => bList.limit;

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

  bool _isClosed;
  @override
  bool get isClosed => (_isClosed == null) ? false : true;

  bool _hadTrailingZeros;
  @override
  bool get hadTrailingZeros => _hadTrailingZeros ?? false;
  ByteData rClose() {
    final view = bdView(0, rIndex_);
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

class LoggingWriteBuffer extends WriteBuffer with WriterLogMixin {
  LoggingWriteBuffer([int length = kDefaultLength,
    Endian endian = Endian.little, int limit = k1GB])
      : super._(length, endian, limit);

  factory LoggingWriteBuffer.fromByteData(
    ByteData bd, [
    int offset = 0,
    int length,
    Endian endian = Endian.little,
    int limit = kDefaultLimit,
  ]) =>
      new LoggingWriteBuffer.fromTypedData(bd, offset, length, endian, limit);

  factory LoggingWriteBuffer.fromBytes(
    Uint8List td, [
    int offset = 0,
    int length,
    Endian endian = Endian.little,
    int limit = kDefaultLimit,
  ]) =>
      new LoggingWriteBuffer.fromTypedData(td, offset, length, endian, limit);

  LoggingWriteBuffer.fromTypedData(
      TypedData td, int offset, int length, Endian endian, int limit)
      : super._fromTD(td, offset, length, endian, limit);
}
