// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/byte_list.dart';

class ByteListReader extends ByteList {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  @override
  final ByteData bd;
  int _rIndex = 0;

  ByteListReader(this.bd);

  factory ByteListReader.from(List<int> iList) =>
      new ByteListReader(new Uint8List.fromList(iList).buffer.asByteData());


  // **** ReadBuffer specific Getters and Methods
  int get rIndex => _rIndex;
  bool get isReadable => _isReadable;
  int get end => bd.lengthInBytes;

  ByteData byteDataView([int start = 0, int end]) =>
      bd.buffer.asByteData(start, end ?? bd.lengthInBytes);

  Uint8List uint8View([int start = 0, int end]) =>
      bd.buffer.asUint8List(start, end ?? bd.lengthInBytes);

  int get uint8 => _readUint8();
  int get uint16 => _readUint16();
  int get uint32 => _readUint32();
  int get uint64 => _readUint64();

  int get code => _readCode();

  /// Peek at next tag - doesn't move the [_rIndex].
  int get peekCode => _getCode(_rIndex);

  int getUint8(int offset) => _getUint8(offset);
  int getUint16(int offset) => _getUint16(offset);
  int getUint32(int offset) => _getUint32(offset);
  int getUint64(int offset) => _getUint64(offset);
  int getCode(int offset) => _getCode(offset);

  /// Moves the [rIndex] forward/backward. Returns the new [rIndex].
  int move(int n) => _move(n);

  // **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _rrr => 'R@${_rIndex.toString(
	).padLeft(
			5, '0')}';

  String get rrr => '$_rrr';

  /// The beginning of reading something.
  String get rbb => '> $_rrr';

  /// In the middle of reading something.
  String get rmm => '| $_rrr  ';

  /// The end of reading something.
  String get ree => '< $_rrr  ';

  String get pad => ''.padRight('$_rrr'.length);

  //TODO: put _checkIndex in appropriate places
  bool checkRIndex() {
    if (_rIndex.isOdd) {
      final msg = 'Odd Lenth Value Field at @$_rIndex - incrementing';
      warn('$msg $_rrr');
      _move(1);
      //TODO: fix
 //     _nOddLengthValueFields++;
      if (throwOnError) throw msg;
    }
    return true;
  }

  bool checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (_getUint8(i) != 0) return false;
    return true;
  }

  void warn(String msg) {
    final s = '**   $msg $_rrr';
    //	  exceptions.add(s);
    log.warn(s);
  }

  void error(String msg) {
    final s = '**** $msg $_rrr';
    //	  exceptions.add(s);
    log.error(s);
  }

  // Internal methods
  bool get _isReadable => _rIndex < bd.lengthInBytes;

  int _getUint8(int offset) => bd.getUint8(offset);

  int _readUint8() {
    assert(_rIndex.isEven);
    final v = _getUint8(_rIndex);
    _rIndex++;
    return v;
  }

  int _getUint16(int offset) {
    assert(offset.isEven);
    return bd.getUint16(offset, Endianness.LITTLE_ENDIAN);
  }

  int _readUint16() {
    assert(_rIndex.isEven);
    final v = _getUint16(_rIndex);
    _rIndex += 2;
    return v;
  }

  int _getUint32(int offset) {
    assert(offset.isEven);
    return bd.getUint32(offset, Endianness.LITTLE_ENDIAN);
  }

  int _readUint32() {
    assert(_rIndex.isEven);
    final v = _getUint32(_rIndex);
    _rIndex += 4;
    return v;
  }

  int _getUint64(int offset) {
    assert(offset.isEven);
    return bd.getUint64(offset, Endianness.LITTLE_ENDIAN);
  }

  int _readUint64() {
    assert(_rIndex.isEven);
    final v = _getUint64(_rIndex);
    _rIndex += 8;
    return v;
  }

  int _getCode(int start) {
    if (_rIndex.isEven && _hasRemaining(4)) {
      final group = _getUint16(start);
      final elt = _getUint16(start);
      return group << 16 & elt;
    }
    // Zero is not a valid code
    return 0;
  }

  /// Reads a group and element and combines them into a Tag.code.
  int _readCode() {
    final code = _getCode(_rIndex);
    _rIndex += 4;
    return code;
  }

  int _move(int n) {
    assert(_rIndex.isEven);
    _rIndex = _rIndex + n;
    return RangeError.checkValidRange(0, _rIndex, bd.lengthInBytes);
  }

  bool _hasRemaining(int n) => (_rIndex + n) <= bd.lengthInBytes;

  void _checkRange(int v) {
    final max = bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  int _isValidBufferLength(int length, [int maxLength = k1GB]) {
    print('isValidlength: $length');
    RangeError.checkValidRange(1, length, maxLength);
    return length;
  }

  static const kMinLength = 768;
}
