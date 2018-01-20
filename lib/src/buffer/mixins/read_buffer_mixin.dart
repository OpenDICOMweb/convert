// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

// ignore_for_file: non_constant_identifier_names

abstract class ReadBufferMixin {
  ByteData get bd;
  Uint8List get bytes;
  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);

  int get rIndex => rIndex_;
  int get wIndex => wIndex_;
  int get rRemaining => bd.lengthInBytes - rIndex_;

  bool get isEmpty => rRemaining <= 0;
  bool get isNotEmpty => !isEmpty;

  bool rHasRemaining(int n) => (rIndex_ + n) <= wIndex_;

  Uint8List get contents => bd.buffer.asUint8List(bd.offsetInBytes, rIndex_);

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;
  bool get isReadable => rIndex_ < wIndex_;


  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    final view = bdView(0, rIndex_);
    if (isNotEmpty) {
      //  warn('End of Data with rIndex_($rIndex) != length(${view.lengthInBytes})');
      hadTrailingZeros = _checkAllZeros(rIndex_, bd.lengthInBytes);
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

  int get rUint8 => readUint8();

  int readUint8() {
    final v = bd.getUint8(rIndex_);
    rIndex_++;
    return v;
  }

  int get rUint16 => readUint16();

  int readUint16() {
    final v = bd.getUint16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  int get rUint32Peek => bd.getUint32(rIndex_);
  int get rUint32 => readUint32();

  int readUint32() {
    final v = bd.getUint32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int get rUint64 => readUint64();

  int readUint64() {
    final v = bd.getUint64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [rIndex_].
  int get peekCode => _peekCode();

  int _peekCode() {
    assert(rIndex_.isEven && rHasRemaining(4), '@$rIndex_ : $rRemaining');
    final group = bd.getUint16(rIndex_);
    final elt = bd.getUint16(rIndex_ + 2);
    return (group << 16) + elt;
  }

  int getCode(int start) => _peekCode();

  int get code => readCode();
  int readCode() {
    final code = getCode(rIndex_);
    rIndex_ += 4;
    return code;
  }

  bool getUint32AndCompare(int target) {
    final delimiter = bd.getUint32(rIndex_);
    final v = target == delimiter;
    return v;
  }

  ByteData bdView([int start = 0, int end]) {
    end ??= wIndex_;
    final length = end - start;
    final offset = _getOffset(start, length);
    return bd.buffer.asByteData(start, length ?? bd.lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asUint8List(offset, length ?? bd.lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(rIndex_, length);

  int _getOffset(int start, int length) {
    final offset = bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= bd.lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= bd.lengthInBytes);
    return offset;
  }
/*

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    final view = rbView(0, rIndex_);
    if (isNotEmpty) {
      //  warn('End of Data with rIndex_($rIndex) != length(${view.lengthInBytes})');
      hadTrailingZeros = _checkAllZeros(rIndex_, bd.lengthInBytes);
    }
    _isClosed = true;
    return view;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros;
*/

/*  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List uint8View(int offset, int lengthInBytes) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, lengthInBytes);

  void _checkRange(int v) {
    final max = bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }*/

  static const int kMinLength = 768;
}

