// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/buffer/mixins/buffer_mixin.dart';
import 'package:convert/src/buffer/mixins/read_buffer_mixin.dart';
import 'package:convert/src/buffer/mixins/write_buffer_mixin.dart';

// ignore_for_file: non_constant_identifier_names

class ReadWriteBuffer extends GrowableByteListBase
    with BufferMixin, ReadBufferMixin, WriteBufferMixin {
  @override
  int rIndex_;
  @override
  int wIndex_;

  ReadWriteBuffer(
      {int length = kDefaultInitialLength, int limit = k1GB, Endian endian =
          kDefaultEndian})
      : super.ofSize(length, endian, limit);

  ReadWriteBuffer.from(ReadWriteBuffer byteList,
      [int offset = 0,
      int length,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : super.fromTypedData(byteList.bd, offset, length, endian, limit);

  ReadWriteBuffer.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : super.fromTypedData(bd, offset, length, endian, limit);

  ReadWriteBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      Endian endian = kDefaultEndian,
      int limit = kDefaultLimit])
      : super.fromTypedData(bytes, offset, length, endian, limit);
}
