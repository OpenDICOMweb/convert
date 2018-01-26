// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

// ignore_for_file: non_constant_identifier_names

abstract class DicomReadMixin {
  ByteData bd;
  int get wIndex_;
  int get wIndex;
  set wIndex_(int n);
  int get wRemaining;
  bool wHasRemaining(int n);
  bool grow([int capacity]);

  /// Write a DICOM Tag Code to _this_.
  void writeCode(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(wIndex_.isEven && wHasRemaining(4));
    _maybeGrow(4);
    bd..setUint16(wIndex_, code >> 16)..setUint16(wIndex_ + 2, code & 0xFFFF);
    wIndex_ += 4;
  }

  /// Grow the buffer if the [wIndex] is at, or beyond, the end of the current buffer.
  bool _maybeGrow([int size = 1]) =>
      ((wIndex_ + size) < bd.lengthInBytes) ? false : grow(wIndex_ + size);


}