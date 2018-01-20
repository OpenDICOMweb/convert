// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

// ignore_for_file: non_constant_identifier_names

abstract class BufferMixin {
  ByteData get bd_;
  Uint8List get bytes_;
  int get rIndex_;
   set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);

  ByteData get bd => bd_;
  Uint8List get bytes => bytes_;

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

  Uint8List get contents => bd.buffer.asUint8List(bd.offsetInBytes, rIndex);


  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;
  bool get isReadable => rIndex_ < wIndex_;



}

