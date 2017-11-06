// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/byte_list.dart';
import 'package:dcm_convert/src/errors.dart';

class ByteReader extends ByteList {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  final ByteData _bd;
  int _rIndex = 0;
  int nonZeroDelimiterLengths = 0;
  int nOddLengthValueFields = 0;
  bool beyondPixelData = false;
  bool hadGroupLengths = false;

  ByteReader(this._bd) : super(_bd);

  factory ByteReader.from(List<int> iList) =>
      new ByteReader(new Uint8List.fromList(iList).buffer.asByteData());

  // **** ReadBuffer specific Getters and Methods

  int operator +(int n) => _indexAdd(n);
  int operator -(int n) => _indexAdd(-n);

  int get index => _rIndex;
  set index(int n) => _setIndexTo(n);

  /// Moves the [rIndex] forward/backward. Returns the new [rIndex].
  int _indexAdd(int n) {
    assert(_hasRemaining(n), '$rmm _hasRemaining($n) +$remaining');
    final index = _rIndex + n;
    return _setIndexTo(index);
  }

  int _setIndexTo(int index) {
    if (index < 0 || index > _bd.lengthInBytes)
      throw new RangeError.range(index, 0, _bd.lengthInBytes);
    return _rIndex = index;
  }

  @override
  ByteData get bd => (_isClosed) ? null : _bd;

  int get rIndex => _rIndex;
  int get remaining => _remaining;
  int get _remaining => _bd.lengthInBytes - _rIndex;
  bool hasRemaining(int n) => _hasRemaining(n);
  bool _hasRemaining(int n) => (_rIndex + n) <= _bd.lengthInBytes;

  int get start => _bd.offsetInBytes;
  int get end => _bd.lengthInBytes;
  bool get isReadable => _isReadable;
  bool get _isReadable => _rIndex < _bd.lengthInBytes;

  @override
  bool get isEmpty => _remaining <= 0;
  @override
  bool get isNotEmpty => !isEmpty;

  ByteData bdView([int start = 0, int end]) {
    final offset = _getOffset(start, length);
    return _bd.buffer.asByteData(start, length ?? _bd.lengthInBytes - offset);
  }

  ByteData readBDView(int length) => bdView(_rIndex, length);

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return _bd.buffer.asUint8List(offset, length ?? _bd.lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(_rIndex, length);

  int _getOffset(int start, int length) {
    final offset = _bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= _bd.lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= _bd.lengthInBytes);
    return offset;
  }

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    _isClosed = true;
    final view = bdView(0, _rIndex);
    if (isNotEmpty) {
      warn('End of Data with _rIndex($rIndex) != length(${view.lengthInBytes})');
      log.debug('$ree, bdLength: $length remaining: $remaining');
      hadTrailingZeros = _checkAllZeros(_rIndex, _bd.lengthInBytes);
      log.debug('Trailing Bytes($_remaining) All Zeros: $hadTrailingZeros');
    }
    return view;
  }

  /// Returns _true_ if this reader [isClosed] and it [isNotEmpty].
  bool get hadTrailingBytes => (_isClosed) ? isNotEmpty : false;
  bool hadTrailingZeros;

  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (_getUint8(i) != 0) return false;
    return true;
  }

  int getUint8(int offset) => _getUint8(offset);
  int _getUint8(int offset) {
    assert(_hasRemaining(1));
    return _bd.getUint8(offset);
  }

  int get uint8 => _readUint8();
  int _readUint8() {
    final v = _getUint8(_rIndex);
    _rIndex++;
    return v;
  }

  int getUint16(int offset) => _getUint16(offset);

  int _getUint16(int offset) {
    assert(offset.isEven && _hasRemaining(2));
    final v = _bd.getUint16(offset, Endianness.LITTLE_ENDIAN);
    return v;
  }

  int get uint16 => _readUint16();
  int _readUint16() {
    final v = _getUint16(_rIndex);
    _rIndex += 2;
    return v;
  }

  int getUint32(int offset) => _getUint32(offset);
  int _getUint32(int offset) {
    assert(offset.isEven && _hasRemaining(4));
    return _bd.getUint32(offset, Endianness.LITTLE_ENDIAN);
  }

  int get uint32 => _readUint32();
  int _readUint32() {
    final v = _getUint32(_rIndex);
    _rIndex += 4;
    return v;
  }

  int get uint64 => _readUint64();
  int _getUint64(int offset) {
    assert(offset.isEven && _hasRemaining(8));
    return _bd.getUint64(offset, Endianness.LITTLE_ENDIAN);
  }

  int getUint64(int offset) => _getUint64(offset);
  int _readUint64() {
    final v = _getUint64(_rIndex);
    _rIndex += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [_rIndex].
  int get peekCode => _peekCode();
  int _peekCode() {
    assert(_rIndex.isEven && _hasRemaining(4));
    final group = _getUint16(_rIndex);
    final elt = _getUint16(_rIndex + 2);
    return (group << 16) + elt;
  }

  int getCode(int offset) => _getCode(offset);
  int _getCode(int start) {
    final code = _peekCode();
    if (code == 0) {
      skip(-4); // undo readTagCode
      _zeroEncountered(code);
      return 0;
    }
    // Check for Group Length Code
    final elt = code & 0xFFFF;
    if (code > 0x3000 && (elt == 0)) hadGroupLengths = true;
    return code;
  }

  int get code => _readCode();
  int _readCode() {
    final code = _getCode(_rIndex);
    _rIndex += 4;
    return code;
  }

  /// Reads a group and element and combines them into a Tag.code.
  int _readCodeFast() {
    final code = _peekCode();
    _rIndex += 4;
    return code;
  }

  /// Returns the Value Field Length (vfLength) of a non-Sequence Element.
  /// The read index [_rIndex] is left at the end of the Element Delimiter.
  //  The [_rIndex] should be at the beginning of the Value Field.
  // Note: Since for binary DICOM the Value Field is 16-bit aligned,
  // it must be checked 16 bits at a time.
  int findEndOfULengthVF() {
    final start = log.down;
    //  log.debug1('$rbb findEndOfULengthVF');
    while (_isReadable) {
      if (_getUint16 != kDelimiterFirst16Bits) continue;
      if (_getUint16 != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    if (!_isReadable) {
      throw new EndOfDataError('_findEndOfVF');
    }
    final delimiterLength = _getUint32;
    if (delimiterLength != 0) {
      nonZeroDelimiterLengths++;
      warn('Encountered non-zero delimiter length($delimiterLength) $rrr');
    }
    final endOfVF = _rIndex - 8;
    //  log.debug1('$ree   endOfVR($endOfVF) eEnd($_rIndex) @end');
    log.up;
    return endOfVF;
  }

  /// Returns true if the sequence delimiter is found at [_rIndex].
  bool isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  /// Returns true if the kItemDelimitationItem32Bit delimiter is found.
  bool isItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

  /// Returns true if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced to the end of the delimiter
  /// field (8 bytes); otherwise, readIndex does not change.
  bool _checkForDelimiter(int target) {
    final delimiter = _getUint32(_rIndex);
    if (delimiter == target) {
      log.debug('$rmm **** Delimiter Target: ${dcm(target)} == ${dcm(delimiter)}');
      _indexAdd(4);
      _readAndCheckDelimiterLength();
      return true;
    }
    return false;
  }

  void _readAndCheckDelimiterLength() {
    final length = _readUint32();
    log.debug('$rmm **** Delimiter Length: $length');
    if (length != 0) {
      nonZeroDelimiterLengths++;
      warn('Encountered non-zero delimiter length($length) $rrr');
    }
  }

  // **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _rrr => 'R@${_rIndex.toString().padLeft(5, '0')}';

  String get rrr => '$_rrr';

  /// The beginning of reading something.
  String get rbb => '> $_rrr';

  /// In the middle of reading something.
  String get rmm => '| $_rrr  ';

  /// The end of reading something.
  String get ree => '< $_rrr  ';

  String get pad => ''.padRight('$_rrr'.length);

  void sMsg(String name, int code, int start,
          {int vrIndex = -1, int vfLength = 999999, int inc = 1}) =>
      _msg(rbb, name, code, start, vrIndex, vfLength, inc);

  void mMsg(String name, int code, int start,
          {int vrIndex = -1, int vfLength = 999999, int inc = 0}) =>
      _msg(rmm, name, code, start, vrIndex, vfLength, inc);

  void _msg(String offset, String name, int code, int start, int vrIndex, int vfLength,
      int inc) {
    final len = (vfLength > 0xFFFE0000) ? '${dcm(vfLength)}' : '$vfLength';
    final s = '$offset $name: ${dcm(code)} vr($vrIndex) $start[$len]';
    log.debug(s, inc);
  }

  void eMsg(Object o, [int inc = -1]) => log.debug('$ree $o $_remaining', inc);

  void warn(Object msg) {
    final s = '**   $msg $_rrr';
    //  _pInfo.exceptions.add(s);
    log.warn(s);
  }

  void error(Object msg) {
    final s = '**** $msg $_rrr';
    //	  exceptions.add(s);
    log.error(s);
  }

  void _checkRange(int v) {
    final max = _bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  //TODO: put _checkIndex in appropriate places
  bool checkIndex() {
    if (_rIndex.isOdd) {
      final msg = 'Odd Lenth Value Field at @$_rIndex - incrementing';
      warn('$msg $_rrr');
      _indexAdd(1);
      nOddLengthValueFields++;
      if (throwOnError) throw msg;
    }
    return true;
  }

  //Enhancement: make this method do more diagnosis.
  /// Returns true if there are only trailing zeros at the end of the
  /// Object being parsed.
  Null _zeroEncountered(int code) {
    final msg = (beyondPixelData) ? 'after kPixelData' : 'before kPixelData';
    warn('Zero encountered $msg $rrr');
    throw new EndOfDataError('Zero encountered $msg $rrr');
  }

  int _isValidBufferLength(int length, [int maxLength = k1GB]) {
    log.debug('isValidlength: $length');
    RangeError.checkValidRange(1, length, maxLength);
    return length;
  }

  static const int kMinLength = 768;
}
