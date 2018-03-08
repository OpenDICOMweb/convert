// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/dcm_writer_base.dart';

abstract class IvrWriter<V> extends DcmWriterBase<V> {
  @override
  final bool isEvr = false;

  @override
  void writeElement(Element e) {
    var vrIndex = e.vrIndex;
    // This should not happen
    if (_isSpecialVR(vrIndex)) {
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }

    if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeIvrDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      _writeIvrSQ(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeIvrMaybeUndefinedLength(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }
  }

  void writeIvrDefinedLength(Element e, int vrIndex) =>
      _writeIvrDefinedLength(e, vrIndex);

  /// Write a non-Sequence Element with a defined length in the Value Field Length field.
  void _writeIvrDefinedLength(Element e, int vrIndex) {
    assert(e.vfLengthField != kUndefinedLength);
    logStartWrite(e, 'writeIvrDefinedLength');
    final eStart = wb.wIndex;
    _writeIvrHeader(e, e.vfLength);
    _writeValueField(e, _getPadChar(e));
    logEndWrite(eStart, e, 'writeIvrDefinedLength');
  }

  int _getPadChar(Element e) =>
      (e is StringBase) ? (e.vrIndex == kUIIndex) ? kNull : kSpace : kNull;

  void _writeIvrMaybeUndefinedLength(Element e, int vrIndex) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeIvrUndefinedLength(e, vrIndex)
          : _writeIvrDefinedLength(e, vrIndex);

  void writeIvrUndefinedLength(Element e, int vrIndex) =>
      _writeIvrUndefinedLength(e, vrIndex);

  /// Write a non-Sequence Element with a Value Field Length field value of
  /// kUndefinedLength.
  void _writeIvrUndefinedLength(Element e, int vrIndex) {
    assert(e.vfLengthField == kUndefinedLength);
    logStartWrite(e, 'writeIvrUndefinedLength');
    final eStart = wb.wIndex;
    _writeIvrHeader(e, kUndefinedLength);
    if (e.code == kPixelData) {
      writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e, kNull);
    }
    wb.writeUint32(kSequenceDelimitationItem32BitLE);
    logEndWrite(eStart, e, 'writeIvrUndefinedLength');
  }

  void _writeIvrSQ(SQ e, int vrIndex) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeIvrSQUndefinedLength(e, vrIndex)
          : _writeIvrSQDefinedLength(e, vrIndex);

  void writeIvrSQDefinedLength(SQ e, int vrIndex) => _writeIvrSQDefinedLength(e, vrIndex);

  void _writeIvrSQDefinedLength(SQ e, int vrIndex) {
    logStartSQWrite(e, 'writeIvrSQDefinedLength');
    final eStart = wb.wIndex;
    _writeIvrHeader(e, e.vfLength);
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfLength = (wb.wIndex - eStart) - 8;
    wb.bd.setUint32(vlfOffset, vfLength);
    logEndSQWrite(eStart, e, 'writeIvrSQDefinedLength');
  }

  void writeIvrSQUndefinedLength(SQ e, int vrIndex) =>
      _writeIvrSQUndefinedLength(e, vrIndex);

  void _writeIvrSQUndefinedLength(SQ e, int vrIndex) {
    logStartSQWrite(e, 'writeIvrSQUndefinedLength');
    final eStart = wb.wIndex;
    _writeIvrHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..writeUint32(kSequenceDelimitationItem32BitLE)..writeUint32(0);
    logEndSQWrite(eStart, e, 'writeIvrSQUndefinedLength');
  }

  void _writeIvrHeader(Element e, int vfLengthField) {
    wb
      ..writeCode(e.code)
      ..writeUint32(vfLengthField);
  }

  void _writeValueField(Element e, int padChar) {
    final bytes = e.vfBytes;
    assert(bytes.lengthInBytes.isEven);
    wb.writeUint8List(bytes);
/* Flush when working
    if (bytes.length.isOdd) {
      log.debug('Odd length VF: ${bytes.length}');
      final padChar = paddingChar(e.vrIndex);
      if (padChar.isNegative) {
        wb.error('Writing padding to a non-padded VR: $e');
        invalidVFLength(e.vfBytes.length, -1);
      }
      wb.uint8(e.padChar);
    }
*/
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
