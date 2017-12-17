// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:dcm_convert/src/binary/base/writer/evr_writer.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

class IvrWriter extends DcmWriterBase {
  @override
  final bool isEvr = false;

  IvrWriter(RootDataset rds, EncodingParameters eParams, int minBDLength, bool reUseBD)
      : super(rds, eParams, minBDLength, reUseBD);

  IvrWriter.from(EvrWriter evrWriter)
      : super(evrWriter.rds, evrWriter.eParams, evrWriter.minBDLength, evrWriter.reUseBD);

  @override
  void writeElement(Element e) {
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      wb.warn('** vrIndex changed to VR.kUN.index');
    }

    if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeIvrDefinedLength(e);
    } else if (_isSequenceVR(vrIndex)) {
      _writeIvrSQ(e);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeIvrMaybeUndefinedLength(e);
//    } else if (_isSpecialVR(vrIndex)) {
//      _writeIvrMaybeUndefined(e);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }

/* Flush when fully working
    if (e.eStart != eStart) {
      log.error('** e.eStart(${e.eStart} != eStart($eStart)');
    }
    if (e.eEnd != wb.wIndex) {
      log.error('** e.eEnd(${e.eStart} != eEnd(${wb.wIndex})');
    }
*/
  }

  void writeIvrDefinedLength(Element e) => _writeIvrDefinedLength(e);

  /// Write a non-Sequence Element with a defined length in the Value Field Length field.
  void _writeIvrDefinedLength(Element e) {
    int padChar = (e.vrIndex == kUIIndex) ? kNull : kSpace;
    assert(e.vfLengthField != kUndefinedLength);
    _writeIvrHeader(e, e.vfLength);
    _writeValueField(e, padChar);
  }

  void _writeIvrMaybeUndefinedLength(Element e) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeIvrUndefinedLength(e)
          : _writeIvrDefinedLength(e);

  void writeIvrUndefinedLength(Element e) => _writeIvrUndefinedLength(e);

  /// Write a non-Sequence Element with a Value Field Length field value of
  /// kUndefinedLength.
  void _writeIvrUndefinedLength(Element e) {
    assert(e.vfLengthField == kUndefinedLength);
    _writeIvrHeader(e, kUndefinedLength);
    if (e.code == kPixelData) {
      writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e, kNull);
    }
    wb.uint32(kSequenceDelimitationItem32BitLE);
  }

  void _writeIvrSQ(SQ e) => (e.hadULength && !eParams.doConvertUndefinedLengths)
      ? _writeIvrSQUndefinedLength(e)
      : _writeIvrSQDefinedLength(e);

  void writeIvrSQDefinedLength(SQ e) => _writeIvrSQDefinedLength(e);

  void _writeIvrSQDefinedLength(SQ e) {
    final eStart = wb.wIndex;
    _writeIvrHeader(e, e.vfLength);
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfLength = (wb.index - eStart) - 8;
    wb.setUint32(vlfOffset, vfLength);
  }

  void writeIvrSQUndefinedLength(SQ e) => _writeIvrSQUndefinedLength(e);

  void _writeIvrSQUndefinedLength(SQ e) {
    _writeIvrHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
  }

  void _writeIvrHeader(Element e, int vfLengthField) {
    wb
      ..code(e.code)
      ..uint32(vfLengthField);
  }

  void _writeValueField(Element e, int padChar) {
    final bytes = e.vfBytes;
    wb.bytes(bytes);
    if (bytes.length.isOdd) {
      log.warn('**** Odd length: ${bytes.length}');
      if (e.padChar.isNegative) return invalidVFLength(e.vfBytes.length, -1);
      wb.uint8(e.padChar);
    }
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
