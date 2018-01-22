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
import 'package:convert/src/byte_list/byte_list_utils.dart';

// ignore_for_file: non_constant_identifier_names

class WriteBuffer extends GrowableByteListBase with BufferMixin, WriteBufferMixin {
  @override
  final int limit;
  @override
  final Endian endian;
  @override
  ByteData bd_;
  @override
  Uint8List bytes_;
  int length_;
  @override
  int rIndex_;
  @override
  int wIndex_;


  WriteBuffer(
      [int length = kDefaultInitialLength,
        this.endian = kDefaultEndian,
        this.limit = kDefaultLimit])
      : bd_ = newBD(length ?? kDefaultInitialLength),
        bytes_ = getBytes(),
        length_ = getLength(),
  rIndex_ = 0,
  wIndex_ = 0;

  WriteBuffer.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      this.endian = kDefaultEndian,
      this.limit = kDefaultLimit])
      : bd_ = asByteData(bd, offset, length ?? kDefaultInitialLength),
        bytes_ = getBytes(),
        length_ = getLength(),
        rIndex_ = 0,
        wIndex_ = 0;

  WriteBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      this.endian = kDefaultEndian,
      this.limit = kDefaultLimit])
      : bytes_ = asUint8List(bytes, offset, length ?? bytes.lengthInBytes),
        bd_ = getByteData(),
        length_ = getLength(),
        rIndex_ = 0,
        wIndex_ = 0;

  WriteBuffer.ofSize(int length, this.endian, this.limit)
      : bd_ = newBD(length),
        bytes_ = getBytes(),
        length_ = getLength(),
        rIndex_ = 0,
        wIndex_ = 0;

  WriteBuffer.fromTypedData(
      TypedData td, int offset, int length, this.endian, this.limit)
      : bd_ = asByteData(td, 0, td.lengthInBytes),
        bytes_ = getBytes(),
        length_ = getLength(),
        rIndex_ = 0,
        wIndex_ = 0;

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

