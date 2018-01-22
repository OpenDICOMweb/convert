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
  bool checkAllZeros(int start, int length);

  int get rIndex => rIndex_;
  set rIndex(int n) {
    if (rIndex < 0 || rIndex > wIndex_) throw new RangeError.range(rIndex, 0, wIndex_);
    rIndex_ = rIndex;
  }

  int rSkip(int n) {
    final v = rIndex_ + n;
    if (v < 0 || v > wIndex_) throw new RangeError.range(v, 0, wIndex_);
    return rIndex_ = v;
  }

  int get rRemaining => bd.lengthInBytes - rIndex_;
  bool get isEmpty => rRemaining <= 0;
  bool get isNotEmpty => !isEmpty;

  bool rHasRemaining(int n) => (rIndex_ + n) <= wIndex_;

  ByteData get contentRead => bd.buffer.asByteData(bd.offsetInBytes, rIndex_);
  ByteData get contentUnread => bd.buffer.asByteData(rIndex_, wIndex_);

  int get rStart => rIndex_;
  int get rEnd => wIndex_;
  bool get isReadable => rIndex_ < wIndex_;

//  int get rInt8 => readInt8();

  int readInt8() {
    final v = bd.getUint8(rIndex_);
    rIndex_++;
    return v;
  }

//  int get rInt16 => readInt16();

  int readInt16() {
    final v = bd.getUint16(rIndex_);
    rIndex_ += 2;
    return v;
  }

//  int get rInt32 => readInt32();

  int readInt32() {
    final v = bd.getUint32(rIndex_);
    rIndex_ += 4;
    return v;
  }

//  int get rInt64 => readInt64();

  int readInt64() {
    final v = bd.getUint64(rIndex_);
    rIndex_ += 8;
    return v;
  }

//  int get rUint8 => readUint8();

  int readUint8() {
    final v = bd.getUint8(rIndex_);
    rIndex_++;
    return v;
  }

//  int get rUint16 => readInt16();

  int readUint16() {
    final v = bd.getUint16(rIndex_);
    rIndex_ += 2;
    return v;
  }

//  int get rUint32 => readUint32();

  int readUint32() {
    final v = bd.getUint32(rIndex_);
    rIndex_ += 4;
    return v;
  }

//  int get rUint64 => readUint64();

  int readUint64() {
    final v = bd.getUint64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  ByteData bdView(int offset, int lengthInBytes) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List byteView(int offset, int lengthInBytes) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, lengthInBytes);

  void checkRange(int v) {
    final max = bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros;

  ByteData close() {
    final view = bdView(0, rIndex_);
    if (isNotEmpty) {
      //  warn('End of Data with rIndex_($rIndex) != length(${view.lengthInBytes})');
      hadTrailingZeros = checkAllZeros(rIndex_, bd.lengthInBytes);
    }
    _isClosed = true;
    return view;
  }

  void get reset {
    rIndex_ = 0;
    wIndex_ = bd.lengthInBytes;
    _isClosed = false;
    hadTrailingZeros = false;
  }


}
