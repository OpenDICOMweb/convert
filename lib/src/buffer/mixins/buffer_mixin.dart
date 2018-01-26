// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';

// ignore_for_file: non_constant_identifier_names

abstract class BufferMixin {
  ByteListBase get bList;
  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);
  bool get isEmpty;

  ByteData get bd;

  Uint8List get bytes;

  Endian get endian => bList.endian;

  int get offsetInBytes => bd.offsetInBytes;
  int get start => bd.offsetInBytes;
  int get length => bytes.length;
  int get lengthInBytes => bd.lengthInBytes;
  int get end => bd.lengthInBytes;

  int get rRemaining => wIndex_ - rIndex_;
  /// Returns the number of writeable bytes left in _this_.
  int get wRemaining => end - wIndex_;

  bool get isReadable => rRemaining > 0;
  bool get isNotReadable => !isReadable;
  bool get isWritable => wRemaining > 0;
  bool get isNotWritable => !isWritable;

  bool get isNotEmpty => !isEmpty;

  bool rHasRemaining(int n) => (rIndex_ + n) <= wIndex_;
  bool wHasRemaining(int n) => (wIndex_ + n) <= end;

  ByteData asByteData(int offset, int length) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, length);

  Uint8List asUint8List(int offset, int length) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, length);


  bool checkAllZeros(int start, int end) {
    final bd = bList.bd;
    for (var i = start; i < end; i++)
      if (bd.getUint8(i) != 0) return false;
    return true;
  }


  // *** Reader specific Getters and Methods

  int get rIndex => rIndex_;
  set rIndex(int n) {
    if (rIndex_ < 0 || rIndex_ > wIndex_) throw new RangeError.range(rIndex, 0, wIndex_);
    rIndex_ = n;
  }

  int rSkip(int n) {
    final v = rIndex_ + n;
    if (v < 0 || v > wIndex_) throw new RangeError.range(v, 0, wIndex_);
    return rIndex_ = v;
  }

  Uint8List get contentsRead =>
      bd.buffer.asUint8List(bd.offsetInBytes, rIndex_);
  Uint8List get contentsUnread => bd.buffer.asUint8List(rIndex_, wIndex_);



  // *** wIndex
  int get wIndex => wIndex_;
  set wIndex(int n) {
    if (wIndex_ <= rIndex_ || wIndex_ > bd.lengthInBytes) throw new RangeError.range(
        wIndex_, rIndex_, bd.lengthInBytes);
    wIndex_ = n;
  }

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int wSkip(int n) {
    final v = wIndex_ + n;
    if (v <= rIndex_ || v >= bd.lengthInBytes) throw new RangeError.range(
        v, 0, bd.lengthInBytes);
    return wIndex_ = v;
  }

  Uint8List get contentsWritten => bd.buffer.asUint8List(rIndex_, wIndex);
}

