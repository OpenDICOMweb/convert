// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';

class ReadBuffer extends ByteList {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  int _rIndex;
  int _wIndex;

  ReadBuffer(ByteData bd, [int offset = 0, int length])
      : _rIndex = 0,
        _wIndex = bd.lengthInBytes,
        super.fromByteData(bd.buffer.asByteData(offset, length));

  ReadBuffer.fromByteData(ByteData bd, [int offset = 0, int length])
      : _rIndex = 0,
        _wIndex = bd.lengthInBytes,
        super.fromByteData(bd.buffer.asByteData(offset, length));

  ReadBuffer.fromUint8List(Uint8List bytes, [int offset = 0, int length])
      : _rIndex = 0,
        _wIndex = bytes.lengthInBytes,
        super.fromUint8List(bytes.buffer.asUint8List(offset, length));

  // **** ReadBuffer specific Getters and Methods

  int get rIndex => _rIndex;
  set rIndex(int n) {
    if (rIndex < 0 || rIndex > _wIndex) throw new RangeError.range(rIndex, 0, _wIndex);
    _rIndex = rIndex;
  }

  int rSkip(int n) {
    final v = _rIndex + n;
    if (v < 0 || v >= _wIndex) throw new RangeError.range(v, 0, _wIndex);
    return _wIndex = v;
  }

  Uint8List get contents => bd.buffer.asUint8List(bd.offsetInBytes, rIndex);

  int get rRemaining => bd.lengthInBytes - rIndex;

  bool hasRemaining(int n) => (_rIndex + n) <= bd.lengthInBytes;

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;
  bool get isReadable => _isReadable;
  bool get _isReadable => _rIndex < bd.lengthInBytes;

  @override
  bool get isEmpty => rRemaining <= 0;

  @override
  bool get isNotEmpty => !isEmpty;

  int get uint8 => readUint8();

  int readUint8() {
    final v = getUint8(_rIndex);
    _rIndex++;
    return v;
  }

  int get uint16 => readUint16();

  int readUint16() {
    final v = getUint16(_rIndex);
    _rIndex += 2;
    return v;
  }

  int get uint32Peek => getUint32(_rIndex);
  int get uint32 => readUint32();

  int readUint32() {
    final v = getUint32(_rIndex);
    _rIndex += 4;
    return v;
  }

  int get uint64 => readUint64();

  int readUint64() {
    final v = getUint64(_rIndex);
    _rIndex += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [_rIndex].
  int get peekCode => _peekCode();

  int _peekCode() {
    assert(_rIndex.isEven && hasRemaining(4), '@$_rIndex : $rRemaining');
    final group = bd.getUint16(_rIndex);
    final elt = bd.getUint16(_rIndex + 2);
    return (group << 16) + elt;
  }

  int getCode(int start) => _peekCode();

  int get code => readCode();
  int readCode() {
    final code = getCode(_rIndex);
    _rIndex += 4;
    return code;
  }

  bool getUint32AndCompare(int target) {
    final delimiter = bd.getUint32(_rIndex);
    final v = target == delimiter;
    return v;
  }

  ByteData bdView([int start = 0, int end]) {
    end ??= rIndex;
    final length = end - start;
    final offset = _getOffset(start, length);
    return bd.buffer.asByteData(start, length ?? bd.lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asUint8List(offset, length ?? bd.lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(_rIndex, length);

  int _getOffset(int start, int length) {
    final offset = bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= bd.lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= bd.lengthInBytes);
    return offset;
  }

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

  static const int kMinLength = 768;

  static ReadBuffer from(ReadBuffer rb, [int offset = 0, int length]) =>
      new ReadBuffer.fromByteData(rb.bd.buffer.asByteData(offset, length));
}
