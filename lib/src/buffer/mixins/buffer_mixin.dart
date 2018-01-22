// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

// ignore_for_file: non_constant_identifier_names

const int _k1GB = 1024 * 1024 * 1024;
const int kDefaultInitialLength = 1024;
const int kDefaultLimit = 10 * _k1GB;
const Endian kDefaultEndian = Endian.little;

abstract class BufferMixin {
  ByteData get bd;
  Uint8List get bytes;
  int get rIndex_;
   set rIndex_(int n);
  int get wIndex_;
  set wIndex_(int n);

  void get reset;
  bool get isEmpty;
  bool get isNotEmpty;
  bool get isClosed;
  ByteData close();

  int get rIndex => rIndex_;
  int get wIndex => wIndex_;

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;
  bool get isReadable => rIndex_ < wIndex_;

  Uint8List get contents => bd.buffer.asUint8List(rIndex_, wIndex_);

  ByteData bdView(int offset, int length) {
    final offset = _getOffset(start, length);
   return bd.buffer.asByteData(offset, length ?? bd.lengthInBytes);
  }

  Uint8List uInt8View(int offset, int length) {
    final offset = _getOffset(start, length);
    return bd.buffer.asUint8List(offset, length ?? bd.lengthInBytes);
  }
  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asUint8List(offset, length ?? bd.lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) {
    final bytes = uint8View(rIndex_, length);
    rIndex_ += length;
    return bytes;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  int _getOffset(int start, int length) {
    final offset = bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= bd.lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= bd.lengthInBytes);
    return offset;
  }

}

