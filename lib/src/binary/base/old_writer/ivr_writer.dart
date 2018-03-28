// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:convert/src/binary/base/padding_chars.dart';


abstract class IvrWriter<V> extends DcmWriterBase<V> {
  static const int vfOffset = 8;
  @override
  final bool isEvr = false;

  void _writeIvrElement(Element e) {
    print(e);
    var vrIndex = e.vrIndex;
    // This should not happen
    if (_isSpecialVR(vrIndex)) {
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }

    if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeLongDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      _writeSequence(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }
  }

  // Urgent same
  /// Write a non-Sequence Element with a defined length in the Value Field Length field.
  void _writeLongDefinedLength(Element e, int vrIndex) {
    assert(e.vfLengthField != kUndefinedLength && wb.index.isEven);
    _writeLongHeader(e, e.vfLength);
    _writeValueField(e);
  }

  // Urgent same
  void _writeMaybeUndefinedLength(Element e, int vrIndex) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeLongUndefinedLength(e, vrIndex)
          : _writeLongDefinedLength(e, vrIndex);

  /// Write a non-Sequence Element with a Value Field Length field value of
  /// kUndefinedLength.
  // Urgent same
  void _writeLongUndefinedLength(Element e, int vrIndex) {
    assert(_isMaybeUndefinedLengthVR(vrIndex) &&
        e.vfLengthField == kUndefinedLength &&
        wb.index.isEven);
    _writeLongHeader(e, kUndefinedLength);
    if (e.code == kPixelData) {
      writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e);
    }
    wb..writeUint32(kSequenceDelimitationItem32BitLE)..writeUint32(0);
    assert(wb.wIndex.isEven);
  }

  // Urgent same
  void _writeSequence(SQ e, int vrIndex) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeSQUndefinedLength(e, vrIndex)
          : _writeSQDefinedLength(e, vrIndex);

  // Urgent same
  void _writeSQDefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && vrIndex == kSQIndex);
    final eStart = wb.wIndex;
    assert(eStart.isEven);
    _writeLongHeader(e, e.vfLength);
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfLength = (wb.wIndex - eStart) - vfOffset;
    assert(vfLength.isEven && wb.wIndex.isEven);
    wb.bd.setUint32(vlfOffset, vfLength);
  }

  // Urgent same
  void _writeSQUndefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && vrIndex == kSQIndex);
    assert(wb.wIndex.isEven);
    _writeLongHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..writeUint32(kSequenceDelimitationItem32BitLE)..writeUint32(0);
    assert(wb.wIndex.isEven);
  }

  // Urgent almost same
  bool _writeLongHeader(Element e, int vfLengthField) {
    assert(e != null && wb.wIndex.isEven);
    final vfLength = e.vfLength;
    assert(vfLength != null);
    final isOddLength = vfLength.isOdd;
    final length = vfLength + (isOddLength ? 1 : 0);
    assert(length.isEven);
    assert(length >= 0 && length < kUndefinedLength, 'length: $length');
    // Urgent same to here
/*    wb
      ..writeCode(e.code)
      ..writeUint32(vfLengthField);*/
    _writeIvrHeader(e, vfLengthField);
    // Urgent same from here
    assert(wb.index.isEven);
    return isOddLength;
  }

  void _writeIvrHeader(Element e, int vfLengthField) {
    wb
      ..writeCode(e.code)
      ..writeUint32(vfLengthField);
  }
  // Urgent same
  void _writeValueField(Element e) {
    assert(wb.wIndex.isEven);
    wb.write(e.vfBytes);
    if (e.vfLength.isOdd) _writePaddingChar(e);
    assert(wb.wIndex.isEven);
  }

  // Urgent same
  void _writePaddingChar(Element e) {
    assert(wb.wIndex.isOdd, 'vfLength: ${e.vfLength} - $e');
    final padChar = paddingChar(e.vrIndex);
    if (padChar.isNegative) {
      log.error('Padding a non-padded Element: $e');
      return invalidVFLength(e.vfBytes.length, -1);
    }
    wb.writeUint8(padChar);
    assert(wb.wIndex.isEven);
  }

  // **** External interface for debugging and monitoring

  @override
  void writeElement(Element e) => _writeIvrElement(e);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void writeDefinedLength(Element e, int vrIndex) =>
      _writeLongDefinedLength(e, vrIndex);

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void writeMaybeUndefinedLength(Element e, int vrIndex) =>
      _writeMaybeUndefinedLength(e, vrIndex);

  /// Write a non-Sequence _undefined length_ Element.
  void writeUndefinedLength(Element e, int vrIndex) =>
      _writeLongUndefinedLength(e, vrIndex);

  /// Write a Sequence Element.
  void writeSequence(SQ e, int vrIndex) => _writeSequence(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQDefinedLength(SQ e, int vrIndex) =>
      _writeSQDefinedLength(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQUndefinedLength(SQ e, int vrIndex) =>
      _writeSQUndefinedLength(e, vrIndex);
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin &&
    vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
