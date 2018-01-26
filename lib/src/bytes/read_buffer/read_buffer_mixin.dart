// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/bytes/bytes.dart';

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_initializing_formals

abstract class ReadBufferMixin {
  Bytes get bytes;
  int get rIndex_;
  set rIndex_(int n);
  int get wIndex_;
  int get remaining;
  bool hasRemaining(int n);

  // **** End of Interface

  int get lengthInBytes => bytes.lengthInBytes;
  int get length => bytes.length;

  set wIndex_(int n) => throw new UnsupportedError('Read Only Buffer');

  int getInt8() => bytes.getInt8(rIndex_);

  int readInt8() {
    final v = bytes.getInt8(rIndex_);
    rIndex_++;
    return v;
  }

  int getInt16() => bytes.getInt16(rIndex_);

  int readInt16() {
    final v = bytes.getInt16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  int getInt32() => bytes.getInt32(rIndex_);

  int readInt32() {
    final v = bytes.getInt32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int getInt64() => bytes.getInt64(rIndex_);

  int readInt64() {
    final v = bytes.getInt64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  int getUint8() => bytes.getUint8(rIndex_);

  int readUint8() {
    final v = bytes.getUint8(rIndex_);
    rIndex_++;
    return v;
  }

  int getUint16() => bytes.getUint16(rIndex_);

  int readUint16() {
    final v = bytes.getUint16(rIndex_);
    rIndex_ += 2;
    return v;
  }

  int getUint32() => bytes.getUint32(rIndex_);

  int readUint32() {
    final v = bytes.getUint32(rIndex_);
    rIndex_ += 4;
    return v;
  }

  int getUint64() => bytes.getUint64(rIndex_);

  int readUint64() {
    final v = bytes.getUint64(rIndex_);
    rIndex_ += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [rIndex_].
  int peekCode() {
    assert(rIndex_.isEven && hasRemaining(4), '@$rIndex_ : $remaining');
    final group = bytes.getUint16(rIndex_);
    final elt = bytes.getUint16(rIndex_ + 2);
    return (group << 16) + elt;
  }

  int getCode(int start) => peekCode();

  int readCode() {
    final code = peekCode();
    rIndex_ += 4;
    return code;
  }

  bool getUint32AndCompare(int target) {
    final delimiter = bytes.getUint32(rIndex_);
    final v = target == delimiter;
    return v;
  }

  ByteData bdView([int start = 0, int end]) {
    end ??= rIndex_;
    final length = end - start;
    final offset = _getOffset(start, length);
    return bytes.asByteData(start, length ?? lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bytes.asUint8List(offset, length ?? lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(rIndex_, length);

  int _getOffset(int start, int length) {
    final offset = bytes.offsetInBytes + start;
    assert(offset >= 0 && offset <= lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= lengthInBytes);
    return offset;
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bytes.buffer.asByteData(bytes.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bytes.buffer.asUint8List(bytes.offsetInBytes + offset, lengthInBytes);

  void checkRange(int v) {
    final max = lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }
}
