// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';

// ignore_for_file: non_constant_identifier_names

abstract class BufferMixin {
  Bytes get bytes;
  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);
  bool get isEmpty;

  ByteData get bd => bytes.bd;

  Endian get endian => bytes.endian;

  int get offsetInBytes => bytes.offsetInBytes;
  int get start => bytes.offsetInBytes;
  int get length => bytes.length;
  int get lengthInBytes => bytes.lengthInBytes;
  int get end => start + lengthInBytes;

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

  Bytes asBytes([int offset = 0, int length]) =>
    //final offset = _getOffset(offset, length);
     bytes.asBytes(offset, length ?? lengthInBytes);


  ByteData asByteData([int offset = 0, int length]) =>
  //  final offset = _getOffset(offset, length);
     bytes.asByteData(offset, length ?? lengthInBytes);

  Uint8List asUint8List([int offset = 0, int length]) =>
      bytes.asUint8List(offset, length ?? lengthInBytes);

  bool checkAllZeros(int offset, int end) {
    for (var i = offset; i < end; i++) if (bytes.getUint8(i) != 0) return false;
    return true;
  }

  // *** Reader specific Getters and Methods

  int get rIndex => rIndex_;
  set rIndex(int n) {
    if (rIndex_ < 0 || rIndex_ > wIndex_)
      throw new RangeError.range(rIndex, 0, wIndex_);
    rIndex_ = n;
  }

  int rSkip(int n) {
    final v = rIndex_ + n;
    if (v < 0 || v > wIndex_) throw new RangeError.range(v, 0, wIndex_);
    return rIndex_ = v;
  }

  Uint8List get contentsRead =>
      bytes.buffer.asUint8List(bytes.offsetInBytes, rIndex_);
  Uint8List get contentsUnread => bytes.buffer.asUint8List(rIndex_, wIndex_);

  // *** wIndex
  int get wIndex => wIndex_;
  set wIndex(int n) {
    if (wIndex_ <= rIndex_ || wIndex_ > bytes.lengthInBytes)
      throw new RangeError.range(wIndex_, rIndex_, bytes.lengthInBytes);
    wIndex_ = n;
  }

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int wSkip(int n) {
    final v = wIndex_ + n;
    if (v <= rIndex_ || v >= bytes.lengthInBytes)
      throw new RangeError.range(v, 0, bytes.lengthInBytes);
    return wIndex_ = v;
  }

  Uint8List get contentsWritten => bytes.buffer.asUint8List(rIndex_, wIndex);
}
