// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/buffer/mixins/buffer_mixin.dart';
import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/buffer/mixins/log_mixins.dart';
import 'package:convert/src/buffer/mixins/read_buffer_mixin.dart';

// ignore_for_file: non_constant_identifier_names

class ReadBuffer extends UnmodifiableByteList with BufferMixin, ReadBufferMixin {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  @override
  int rIndex_;
  @override
  int wIndex_;

  ReadBuffer(ByteData bd, [int offset = 0, int length, Endian endian = kDefaultEndian])
      : rIndex_ = offset ?? 0,
        wIndex_ = length ?? bd.lengthInBytes,
        super.fromTypedData(bd, offset, length, endian);

  ReadBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = kDefaultEndian])
      : rIndex_ = offset ?? 0,
        wIndex_ = length ?? bytes.lengthInBytes,
        super.fromTypedData(bytes, offset, length, endian);

  ReadBuffer.fromTypedData(TypedData td, int offset, int length, Endian endian)
      : rIndex_ = offset ?? 0,
        wIndex_ = length ?? td.lengthInBytes,
        super.fromTypedData(td, offset, length, endian);

  int get remaining => rRemaining;
  bool hasRemaining(int n) => rHasRemaining(n);

  static ReadBuffer from(ReadBuffer rb, [int offset = 0, int length]) =>
      new ReadBuffer(rb.bd.buffer.asByteData(offset, length));
}

class LoggingReadBuffer extends ReadBuffer with LoggingReaderMixin {
  factory LoggingReadBuffer(ByteData bd,
          [int offset = 0, int length, Endian endian = kDefaultEndian]) =>
      new LoggingReadBuffer._(bd, offset, length, endian);

  factory LoggingReadBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = kDefaultEndian]) {
    final bd = bytes.buffer.asByteData(offset, length);
    return new LoggingReadBuffer._(bd, offset, length, endian);
  }

  LoggingReadBuffer._(ByteData bd, int offset, int length, Endian endian)
      : super.fromTypedData(bd.buffer.asByteData(offset, length), 0, length, endian);
}
