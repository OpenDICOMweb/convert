// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/writer/ivr_writer.dart';
import 'package:convert/src/dicom/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/element_offsets.dart';

//Urgent: remove all log.debug
abstract class LoggingIvrWriter extends IvrWriter<int> with LogWriteMixin {
  @override
   ParseInfo get pInfo;
  @override
   ElementOffsets  get inputOffsets;
  @override
   ElementOffsets get outputOffsets;
  @override
  int get elementCount;
  set elementCount(int n);

  @override
  void writeElement(Element e) {
    logStartWrite(e, 'writeIvrElement');
    elementCount++;
    final eStart = wIndex_;
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }

    log.debug('$wbb #$elementCount writeIvrElement $e :$wRemaining', 1);
    if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeIvrDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      _writeIvrSQ(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeIvrMaybeUndefined(e, vrIndex);
//    } else if (_isSpecialVR(vrIndex)) {
//      _writeIvrMaybeUndefined(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }

    if (e.eStart != eStart) {
      log.error('** e.eStart(${e.eStart} != eStart($eStart)');
    }
    if (e.eEnd != wIndex_) {
      log.error('** e.eEnd(${e.eStart} != eEnd($wIndex_)');
    }

    pInfo.nElements++;
    doEndOfElementStats(eStart, wIndex_, e);
    log.debug('$wee writeIvrElement ${e.dcm} ${e.keyword}');
  }

  /// Write a non-Sequence Element with a defined length in the Value Field Length field.
  void _writeIvrDefinedLength(Element e, int vrIndex) {
    log.debug('$wbb writeSimpleIvr $e :$wRemaining', 1);
    super.writeIvrDefinedLength(e, vrIndex);
    pInfo.nLongElements++;
  }

  void _writeIvrMaybeUndefined(Element e, int vrIndex) {
    log.debug('$wbb writeIvrMaybeUndefined $e :$wRemaining', 1);
    pInfo.nMaybeUndefinedElements++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeIvrUndefinedLength(e, vrIndex)
        : _writeIvrDefinedLength(e, vrIndex);
  }

  /// Write a non-Sequence Element with a Value Field Length field value of
  /// kUndefinedLength.
  void _writeIvrUndefinedLength(Element e, int vrIndex) {
    assert(e.vfLengthField == kUndefinedLength);
    log.debug('$wmm writeIvrUndefined $e :$wRemaining');
    super.writeIvrUndefinedLength(e, vrIndex);
    if (e.code == kPixelData) pInfo.pixelDataEnd = wIndex_;
    pInfo.nUndefinedLengthElements++;
    log.debug('$wbb writeIvrUndefined $e :$wRemaining', 1);
  }

  void _writeIvrSQ(SQ e, int vrIndex) {
    pInfo.nSequences++;
    if (e.isPrivate) pInfo.nPrivateSequences++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeIvrSQUndefinedLength(e, vrIndex)
        : _writeIvrSQDefinedLength(e, vrIndex);
  }

  void _writeIvrSQDefinedLength(SQ e, int vrIndex) {
    log.debug('$wbb _writeIvrSQDefined $e :$wRemaining', 1);
    final index = outputOffsets.reserveSlot;
    pInfo.nDefinedLengthSequences++;
    final eStart = wIndex_;

    super.writeIvrSQDefinedLength(e, vrIndex);

    final eEnd = wIndex_;
    assert(e.vfLength + 8 == e.eEnd - e.eStart, '${e.vfLength}, $eEnd - $eStart');
    assert(e.vfLength + 8 == (eEnd - eStart), '${e.vfLength}, $eEnd - $eStart');
    outputOffsets.insertAt(index, eStart, eEnd, e);
  }

  void _writeIvrSQUndefinedLength(SQ e, int vrIndex) {
    log.debug('$wbb _writeIvrSQUndefined $e :$wRemaining', 1);
    final index = outputOffsets.reserveSlot;
    final eStart = wIndex_;
    super.writeIvrSQUndefinedLength(e, vrIndex);
    pInfo.nUndefinedLengthSequences++;
    outputOffsets.insertAt(index, eStart, wIndex_, e);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
