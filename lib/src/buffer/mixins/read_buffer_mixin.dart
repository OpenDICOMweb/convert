// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

abstract class ReadBufferMixin {
  ImmutableByteList get bList;
  int get lengthInBytes;
  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;

  int get remaining;
  bool hasRemaining(int n);

  set wIndex_(int n) => throw new UnsupportedError('Read Only Buffer');

  int getInt8() => bList.getInt8(rIndex_);

  int readInt8() {
    final v = bList.getInt8(rIndex_);
    rIndex_++;
    return v;
  }

  int getInt16() => bList.getInt16(rIndex_);

  int readInt16() {
    final v = bList.getInt16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  int getInt32() => bList.getInt32(rIndex_);

  int readInt32() {
    final v = bList.getInt32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int getInt64() => bList.getInt64(rIndex_);

  int readInt64() {
    final v = bList.getInt64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  int getUint8() => bList.getUint8(rIndex_);

  int readUint8() {
    final v = bList.getUint8(rIndex_);
    rIndex_++;
    return v;
  }

  int getUint16() => bList.getUint16(rIndex_);

  int readUint16() {
    final v = bList.getUint16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  Uint16List readUint16List(int length) {
    final vList = new Uint16List(length);
    final end = rIndex_ + (length * 2);
    for (var i = rIndex_; i < end; i++) vList[i] = bList.getUint16(i);
    rIndex_ = end;
    return vList;
  }

  int getUint32() => bList.getUint32(rIndex_);

  int readUint32() {
    final v = bList.getUint32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int getUint64() => bList.getUint64(rIndex_);

  int readUint64() {
    final v = bList.getUint64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [rIndex_].
  int peekCode() {
    assert(rIndex_.isEven && hasRemaining(4), '@$rIndex_ : $remaining');
    final group = bList.getUint16(rIndex_);
    final elt = bList.getUint16(rIndex_ + 2);
    return (group << 16) + elt;
  }

  int getCode(int start) => peekCode();

  int readCode() {
    final code = peekCode();
    rIndex_ += 4;
    return code;
  }

  bool getUint32AndCompare(int target) {
    final delimiter = bList.getUint32(rIndex_);
    final v = target == delimiter;
    return v;
  }

  ByteData bdView([int start = 0, int end]) {
    end ??= rIndex_;
    final length = end - start;
    final offset = _getOffset(start, length);
    return bList.bd.buffer.asByteData(start, length ?? lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bList.bd.buffer
        .asUint8List(offset, length ?? lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(rIndex_, length);

  int _getOffset(int start, int length) {
    final offset = bList.offsetInBytes + start;
    assert(offset >= 0 && offset <= lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= lengthInBytes);
    return offset;
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bList.buffer.asByteData(bList.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bList.buffer.asUint8List(bList.offsetInBytes + offset, lengthInBytes);

  void checkRange(int v) {
    final max = lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }
}
