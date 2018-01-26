// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';
import 'package:convert/src/bytes/buffer/buffer_base.dart';
import 'package:convert/src/bytes/read_buffer/read_buffer_mixin.dart';
import 'package:convert/src/bytes/buffer/log_mixins.dart';


// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

class ReadBuffer extends BufferBase with ReadBufferMixin {
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

  ReadBuffer(ByteData bd,
      [int offset = 0, int length, Endian endian = Endian.little])
      : rIndex_ = offset,
        wIndex_ = offset + (length ?? bd.lengthInBytes),
        bytes = new Bytes.fromByteData(bd, offset, length, endian);

  ReadBuffer.from(ReadBuffer rb,
                           [int offset = 0, int length, Endian endian = Endian.little])
      : rIndex_ = offset,
        wIndex_ = offset + (length ?? rb.lengthInBytes),
        bytes =
        new Bytes.from(rb.bytes, offset, length, endian);

  ReadBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = Endian.little])
      : rIndex_ = offset,
        wIndex_ = offset + (length ?? bytes.lengthInBytes),
        bytes =
            new Bytes.fromTypedData(bytes, offset, length, endian);

  ReadBuffer.fromTypedData(TypedData bd, int offset, int length, Endian endian)
      : rIndex_ = offset,
        wIndex_ = offset + (length ?? bd.lengthInBytes),
        bytes = new Bytes.fromTypedData(bd, offset, length, endian);

  // **** ReadBuffer specific Getters and Methods

  @override
  int get remaining => rRemaining;

  @override
  bool get isEmpty => isNotReadable;

  @override
  bool hasRemaining(int n) => rHasRemaining(n);

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (isClosed) ? isNotEmpty : false;
  bool _hadTrailingZeros;
  bool get hadTrailingZeros => _hadTrailingZeros ?? false;

  @override
  void get reset {
    super.reset;
    _hadTrailingZeros = null;
  }
}

class LoggingReadBuffer extends ReadBuffer with ReaderLogMixin {
  factory LoggingReadBuffer(ByteData bd,
          [int offset = 0, int length, Endian endian = Endian.little]) =>
      new LoggingReadBuffer._(bd, offset, length, endian);

  factory LoggingReadBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = Endian.little]) {
    final bd = bytes.buffer.asByteData(offset, length);
    return new LoggingReadBuffer._(bd, offset, length, endian);
  }

  LoggingReadBuffer._(TypedData td, int offset, int length, Endian endian)
      : super.fromTypedData(
            td.buffer.asByteData(offset, length), 0, length, endian);
}
