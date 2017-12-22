// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:element/element.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/byte_list.dart';
import 'package:dcm_convert/src/binary/base/padding_chars.dart';

class ReadBuffer extends ByteList {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  int _index = 0;

  ReadBuffer(ByteData bd) : super(bd);

  ReadBuffer.from(List<int> iList)
      : super(new Uint8List.fromList(iList).buffer.asByteData());

  // **** ReadBuffer specific Getters and Methods

  int operator +(int n) => _indexAdd(n);
  int operator -(int n) => _indexAdd(-n);

  int get index => _index;
  set index(int n) => _setIndexTo(n);

  /// Moves the [index] forward/backward. Returns the new [index].
  int _indexAdd(int n) {
    assert(_hasRemaining(n), 'hasRemaining($n) +$remaining');
    final index = _index + n;
    return _setIndexTo(index);
  }

  int _setIndexTo(int index) {
    if (index < 0 || index > bd.lengthInBytes)
      throw new RangeError.range(index, 0, bd.lengthInBytes);
    return _index = index;
  }

  @override
  ByteData get bd => (_isClosed) ? null : super.bd;

  Uint8List get bytes => bd.buffer.asUint8List(bd.offsetInBytes, index);

  int get remaining => _remaining;
  int get _remaining => super.bd.lengthInBytes - _index;
  bool hasRemaining(int n) => _hasRemaining(n);
  bool _hasRemaining(int n) => (_index + n) <= bd.lengthInBytes;

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;
  bool get isReadable => _isReadable;
  bool get _isReadable => _index < bd.lengthInBytes;

  @override
  bool get isEmpty => _remaining <= 0;
  @override
  bool get isNotEmpty => !isEmpty;

  ByteData bdView([int start = 0, int end]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asByteData(start, length ?? bd.lengthInBytes - offset);
  }

  Uint8List uint8View([int start = 0, int length]) {
    final offset = _getOffset(start, length);
    return bd.buffer.asUint8List(offset, length ?? bd.lengthInBytes - offset);
  }

  Uint8List readUint8View(int length) => uint8View(_index, length);

  int _getOffset(int start, int length) {
    final offset = bd.offsetInBytes + start;
    assert(offset >= 0 && offset <= bd.lengthInBytes);
    assert(offset + length >= offset && (offset + length) <= bd.lengthInBytes);
    return offset;
  }

  bool get isClosed => _isClosed;
  bool _isClosed = false;

  ByteData close() {
    final view = bdView(0, _index);
    if (isNotEmpty) {
      warn('End of Data with _index($index) != length(${view.lengthInBytes})');
      hadTrailingZeros = _checkAllZeros(_index, bd.lengthInBytes);
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

  @override
  int getUint8(int offset) => bd.getUint8(offset);

  int get uint8 => readUint8();

  int readUint8() {
    final v = bd.getUint8(_index);
    _index++;
    return v;
  }

  int get uint16 => readUint16();

  int readUint16() {
    final v = getUint16(_index);
    _index += 2;
    return v;
  }

  int get uint32Peek => getUint32(_index);
  int get uint32 => readUint32();

  int readUint32() {
    final v = getUint32(_index);
    _index += 4;
    return v;
  }

  int get uint64 => readUint64();

  int readUint64() {
    final v = getUint64(_index);
    _index += 8;
    return v;
  }

  /// Peek at next tag - doesn't move the [_index].
  int get peekCode => _peekCode();
  int _peekCode() {
    assert(_index.isEven && _hasRemaining(4));
    final group = getUint16(_index);
    final elt = getUint16(_index + 2);
    return (group << 16) + elt;
  }

  int getCode(int start) => _peekCode();

  int get code => readCode();
  int readCode() {
    final code = getCode(_index);
    _index += 4;
    return code;
  }

  /// Reads a group and element and combines them into a Tag.code.
  int _readCodeFast() {
    final code = _peekCode();
    _index += 4;
    return code;
  }

  bool getUint32AndCompare(int target) {
    final delimiter = getUint32(_index);
    final v = target == delimiter;
    return v;
  }

  // If the vr has a padding char and if padding is present remove it.
  int _getLength(int eStart, int vrIndex) {
    var length = _index - eStart;
    if (length.isOdd) log.warn('Value Field with odd length: "s"');
    final padChar = paddingChar(vrIndex);
    if (padChar >= 0) {
      final char = bd.getUint8(_index - 1);
      if (char == kSpace || char == kNull) {
        length--;
        if (char != padChar) log.warn(
            '** Warning: Invalid Padding Char($char) should be $padChar');
      }
    }
    return length;
  }

  /// Returns [EBytes] for an [EvrShort] [Element]. [eStart] is the index
  /// of the first byte of _this_ [EBytes], and [index] must be the index
  /// of the byte after the last byte of the [Element]. [EvrShort] [Element]s
  /// always have a defined length.
  EBytes  makeEvrShortEBytes(int eStart, int vrIndex) {
    final length = _getLength(eStart, vrIndex);
    final ebd = bd.buffer.asByteData(bd.offsetInBytes + eStart, length);
    return EvrShort.make(ebd);
  }

  /// Returns [EBytes] for an [EvrLong] [Element]. [eStart] is the index
  /// of the first byte of _this_ [EBytes], and [index] must be the index
  /// of the byte after the last byte of the [Element]. [EvrLong] [Element]s
  /// MUST always have a defined length.
  EBytes makeEvrLongEBytes(int eStart, int vrIndex) {
    final length = _getLength(eStart, vrIndex);
    final ebd = bd.buffer.asByteData(bd.offsetInBytes + eStart, length);
    return EvrLong.make(ebd);
  }

  /// Returns [EBytes] for an [EvrLong] [Element] with a kUndefinedLength Value
  /// Field length. [eStart] is the index of the first byte of _this_ [EBytes], and
  /// [index] must be the index of the byte after the last byte of the [Element].
  /// [EvrLong] [Element]s MUST always have kUndefinedLength in the Value Field
  /// length field.
  EBytes makeEvrULengthEBytes(int eStart, int vrIndex) {
    final length = _getLength(eStart, vrIndex);
    final ebd = bd.buffer.asByteData(bd.offsetInBytes + eStart, length);
    return EvrULength.make(ebd);
  }

  /// Returns [EBytes] for an [IVR] [Element] with defined length. [eStart] is
  /// the index of the first byte of _this_ [EBytes], and [index] must be the index
  /// of the byte after the last byte of the [Element]. [Ivr] [Element]s MUST always
  /// have a defined length.
  EBytes makeIvrEBytes(int eStart, int vrIndex) {
    final length = _getLength(eStart, vrIndex);
    final ebd = bd.buffer.asByteData(bd.offsetInBytes + eStart, length);
    return Ivr.make(ebd);
  }

  /// Returns [EBytes] for an [Ivr] [Element] with a kUndefinedLength Value
  /// Field length. [eStart] is the index of the first byte of _this_ [EBytes], and
  /// [index] must be the index of the byte after the last byte of the [Element].
  /// [EvrLong] [Element]s MUST always have kUndefinedLength in the Value Field
  /// length field.
  EBytes makeIvrULengthEBytes(int eStart, int vrIndex) {
    final length = _getLength(eStart, vrIndex);
    final ebd = bd.buffer.asByteData(bd.offsetInBytes + eStart, length);
    return EvrULength.make(ebd);
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, lengthInBytes);

  void warn(Object msg) {
    final s = '**   $msg';
    log.warn(s);
  }

  void error(Object msg) {
    final s = '**** $msg';
    log.error(s);
  }

  void checkRange(int v) {
    final max = bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }

  static const int kMinLength = 768;
}
