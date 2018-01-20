// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/buffer/mixins/log_mixins.dart';
import 'package:convert/src/buffer/mixins/buffer_mixin.dart';
import 'package:convert/src/buffer/mixins/read_buffer_mixin.dart';

class ReadBuffer extends ImmutableByteList with ReadBufferMixin {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  @override
  int rIndex_;
  @override
  int wIndex_;

  ReadBuffer(ByteData bd, [int offset = 0, int length, Endian endian = Endian.little])
      : rIndex_ = 0,
        wIndex_ = bd.lengthInBytes,
        super.internal(bd.buffer.asByteData(offset, length), endian);

  ReadBuffer.fromUint8List(Uint8List bytes,
      [int offset = 0, int length, Endian endian = Endian.little])
      : rIndex_ = 0,
        wIndex_ = bytes.lengthInBytes,
        super.fromUint8List(bytes.buffer.asUint8List(offset, length), endian);

  ReadBuffer._(ByteData bd, int offset, int length, Endian endian)
      : rIndex_ = 0,
        wIndex_ = bd.lengthInBytes,
        super.internal(bd.buffer.asByteData(offset, length), endian);

  /*
  // **** ReadBuffer specific Getters and Methods

  int get rIndex => _rIndex;

  set rIndex(int n) {
    if (rIndex < 0 || rIndex > _wIndex) throw new RangeError.range(rIndex, 0, _wIndex);
    _rIndex = rIndex;
  }

  int rSkip(int n) {
    final v = _rIndex + n;
    if (v < 0 || v > _wIndex) throw new RangeError.range(v, 0, _wIndex);
    return _rIndex = v;
  }


  @override
  bool get isEmpty => rRemaining <= 0;

  @override
  bool get isNotEmpty => !isEmpty;


  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    final view = bdView(0, _rIndex);
    if (isNotEmpty) {
      //  warn('End of Data with _rIndex($rIndex) != length(${view.lengthInBytes})');
      hadTrailingZeros = _checkAllZeros(_rIndex, bd.lengthInBytes);
    }
    _isClosed = true;
    return view;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros;

  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, lengthInBytes);

  void checkRange(int v) {
    final max = bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }
*/

  static const int kMinLength = 768;

  static ReadBuffer from(ReadBuffer rb, [int offset = 0, int length]) =>
      new ReadBuffer(rb.bd.buffer.asByteData(offset, length));
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

  LoggingReadBuffer._(ByteData bd, int offset, int length, Endian endian)
      : super._(bd.buffer.asByteData(offset, length), 0, length, endian);
}
