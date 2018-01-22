// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/buffer/mixins/log_mixins.dart';
import 'package:convert/src/dicom/base/writer/evr_writer.dart';
import 'package:convert/src/dicom/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/element_offsets.dart';

abstract class LoggingEvrWriter extends EvrWriter<int> with LoggingWriterMixin {

  @override
   ParseInfo get pInfo;
  @override
   ElementOffsets get inputOffsets;
  @override
   ElementOffsets get outputOffsets;
  @override
  int get elementCount;
  set elementCount(int n);

  @override
  void writeElement(Element e) {
    logStartWrite(e, 'writeEvrElement');
    elementCount++;
    final eStart = wIndex_;
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }

    log.debug('$wbb #$elementCount writeEvrElement $e :$wRemaining', 1);
    if (_isEvrShortLengthVR(vrIndex)) {
      writeShort(e, vrIndex);
    } else if (_isEvrLongLengthVR(vrIndex)) {
      writeLongDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      writeSequence(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      writeMaybeUndefined(e, vrIndex);
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
    log.debug('$wee #$elementCount writeEvrElement ${e.dcm} ${e.keyword}', -2);
  }

  @override
  void writeShort(Element e, int vrIndex) {
    log.debug('$wbb writeShortEvr $e :$wRemaining', 1);
    super.writeShortEvr(e, vrIndex);
    pInfo.nShortElements++;
  }

  /// Write a non-Sequence _defined length_ Element.
  @override
  void writeLongDefinedLength(Element e, int vrIndex) {
    log.debug('$wbb writeLongEvrDefinedLength $e :$wRemaining', 1);
    super.writeLongEvrDefinedLength(e, vrIndex);
    pInfo.nLongElements++;
  }

  @override
  void writeMaybeUndefined(Element e, int vrIndex) {
    log.debug('$wbb writeEvrMaybeUndefined $e :$wRemaining', 1);

    super.writeEvrMaybeUndefined(e, vrIndex);

    pInfo.nMaybeUndefinedElements++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeLongEvrUndefinedLength(e, vrIndex)
        : writeLongDefinedLength(e, vrIndex);
  }

  void _writeLongEvrUndefinedLength(Element e, int vrIndex) {
    log.debug('$wmm writeEvrUndefined $e :$wRemaining');

    super.writeLongEvrUndefinedLength(e, vrIndex);

    pInfo.nUndefinedLengthElements++;
  }

  @override
  void writeSequence(SQ e, int vrIndex) {
    pInfo.nSequences++;
    if (e.isPrivate) pInfo.nPrivateSequences++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeEvrSQUndefinedLength(e, vrIndex)
        : _writeEvrSQDefinedLength(e, vrIndex);
  }

  void _writeEvrSQDefinedLength(SQ e, int vrIndex) {
    log.debug('$wbb writeEvrSQDefinedLength $e :$wRemaining', 1);
    final index = outputOffsets.reserveSlot;
    pInfo.nDefinedLengthSequences++;
    final eStart = wIndex_;

    super.writeEvrSQUndefinedLength(e, vrIndex);

    final eEnd = wIndex_;
    assert(e.vfLength + 12 == e.eEnd - e.eStart, '${e.vfLength}, $eEnd - $eStart');
    assert(e.vfLength + 12 == (eEnd - eStart), '${e.vfLength}, $eEnd - $eStart');
    outputOffsets.insertAt(index, eStart, eEnd, e);
  }

  void _writeEvrSQUndefinedLength(SQ e, int vrIndex) {
    log.debug('$wbb writeEvrSQUndefinedLength $e :$wRemaining', 1);
    final eStart = wIndex_;
    final index = outputOffsets.reserveSlot;
    super.writeEvrSQUndefinedLength(e, vrIndex);
    pInfo.nUndefinedLengthSequences++;
    outputOffsets.insertAt(index, eStart, wIndex_, e);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongLengthVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortLengthVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;
