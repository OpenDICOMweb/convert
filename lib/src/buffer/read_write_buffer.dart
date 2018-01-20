// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/buffer/mixins/read_buffer_mixin.dart';
import 'package:convert/src/buffer/mixins/write_buffer_mixin.dart';

// ignore_for_file: non_constant_identifier_names

const int k1GB = 1024 * 1024 * 1024;

class ReadWriteBuffer extends GrowableByteList
    with ReadBufferMixin, WriteBufferMixin {
  @override
  int rIndex_;
  @override
  int wIndex_;

  ReadWriteBuffer(
      {int length = kDefaultLength,
      int limit = k1GB,
      Endian endian = Endian.little})
      : super(length, limit, endian);

  ReadWriteBuffer.from(ReadWriteBuffer byteList,
  {int limit = k1GB, Endian  endian= Endian.little)
      : super.from(byteList);

  ReadWriteBuffer.fromByteData(ByteData bd,
      {int limit = k1GB, Endian endian = Endian.little})
      : super.fromBD(bd, limit ,   endian);

  ReadWriteBuffer.fromUint8List(Uint8List bytes,
      [int limit = k1GB, Endian  endian = Endian.little])
      : super.fromBD(bytes.buffer.asByteData(), limit, endian);

  void debug(String msg, {int level]) => log.debug(msg, level);

  static const int kDefaultLength = 4 * k1KB;
}
