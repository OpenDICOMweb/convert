// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/buffer/mixins/buffer_mixin.dart';
import 'package:convert/src/buffer/mixins/log_mixins.dart';
import 'package:convert/src/buffer/mixins/write_buffer_mixin.dart';
import 'package:convert/src/byte_list/byte_list.dart';

// ignore_for_file: non_constant_identifier_names

class WriteBuffer extends GrowableByteListBase with BufferMixin, WriteBufferMixin {
  @override
  int rIndex_;
  @override
  int wIndex_;

  WriteBuffer(
      [int length = kDefaultInitialLength,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : rIndex_ = 0,
        wIndex_ = 0,
        super.ofSize(length, endian, limit);

  WriteBuffer.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : rIndex_ = 0,
        wIndex_ = 0,
        super.fromTypedData(bd, offset, length, endian, limit);

  WriteBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : rIndex_ = 0,
        wIndex_ = 0,
        super.fromTypedData(bytes, offset, length, endian, limit);

  WriteBuffer.ofSize(int length, Endian endian, int limit)
      : rIndex_ = 0,
        wIndex_ = 0,
        super.fromTypedData(
            new ByteData(length ?? kDefaultInitialLength), 0, length, endian, limit);

  WriteBuffer.fromTypedData(
      TypedData td, int offset, int length, Endian endian, int limit)
      : rIndex_ = 0,
        wIndex_ = 0,
        super.fromTypedData(td, offset, length ?? td.lengthInBytes, endian, limit);

  @override
  ByteData get bd => (isClosed) ? null : super.bd;

  int get remaining => wRemaining;

  @override
  String toString() => '$runtimeType($length)[$wIndex_] maxLength: $limit';

  static WriteBuffer from(WriteBuffer wb, [int offset = 0, int length]) =>
      new WriteBuffer.fromByteData(wb.bd.buffer.asByteData(offset, length));

}

class LoggingWriteBuffer extends WriteBuffer with LoggingWriterMixin {
  LoggingWriteBuffer(
      [int length = kDefaultInitialLength,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : super.ofSize(length, endian, limit);

  LoggingWriteBuffer.fromByteData(ByteData bd,
      [int offset = 0, int length, Endian endian = kDefaultEndian, int limit])
      : super.fromTypedData(bd, offset, length, endian, limit);

  LoggingWriteBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = kDefaultEndian, int limit])
      : super.fromTypedData(bytes, offset, length, endian, limit);
}

