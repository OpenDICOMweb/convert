// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/evr_writer.dart';
import 'package:convert/src/binary/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/element_offsets.dart';

abstract class LoggingEvrWriter extends EvrWriter<int> with LogWriteMixin {

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
    logStartWrite(e, 'writeElement');
    elementCount++;
    final eStart = wb.wIndex;
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }

//    log.debug('${wb.wbb} #$elementCount writeElement $e :${wb.remaining}', 1);
    if (_isShortLengthVR(vrIndex)) {
      writeShort(e, vrIndex);
    } else if (_isLongLengthVR(vrIndex)) {
      writeLongDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      writeSequence(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }

    if (e.eStart != eStart) {
      log.error('** e.eStart(${e.eStart} != eStart($eStart)');
    }
    if (e.eEnd != wb.wIndex) {
      log.error('** e.eEnd(${e.eStart} != eEnd(${wb.wIndex})');
    }

    pInfo.nElements++;
    doEndOfElementStats(eStart, wb.wIndex, e);
//    log.debug('${wb.wee} #$elementCount writeElement ${e.dcm} ${e.keyword}', -2);
  }

  @override
  void writeShort(Element e, int vrIndex) {
//    log.debug('${wb.wbb} writeShort $e :${wb.remaining}', 1);
    super.writeShort(e, vrIndex);
    pInfo.nShortElements++;
  }

  /// Write a non-Sequence _defined length_ Element.
  @override
  void writeLongDefinedLength(Element e, int vrIndex) {
//    log.debug('${wb.wbb} writeLongDefinedLength $e :${wb.remaining}', 1);
    super.writeLongDefinedLength(e, vrIndex);
    pInfo.nLongElements++;
  }

  @override
  void writeMaybeUndefinedLength(Element e, int vrIndex) {
//    log.debug('${wb.wbb} writeMaybeUndefined $e :${wb.remaining}', 1);

    super.writeMaybeUndefinedLength(e, vrIndex);

    pInfo.nMaybeUndefinedElements++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeLongUndefinedLength(e, vrIndex)
        : writeLongDefinedLength(e, vrIndex);
  }

  void _writeLongUndefinedLength(Element e, int vrIndex) {
//    log.debug('${wb.wmm} writeUndefined $e :${wb.remaining}');

    super.writeLongUndefinedLength(e, vrIndex);

    pInfo.nUndefinedLengthElements++;
  }

  @override
  void writeSequence(SQ e, int vrIndex) {
    pInfo.nSequences++;
    if (e.isPrivate) pInfo.nPrivateSequences++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeSQUndefinedLength(e, vrIndex)
        : _writeSQDefinedLength(e, vrIndex);
  }

  void _writeSQDefinedLength(SQ e, int vrIndex) {
//    log.debug('${wb.wbb} writeSQDefinedLength $e :${wb.remaining}', 1);
    final index = outputOffsets.reserveSlot;
    pInfo.nDefinedLengthSequences++;
    final eStart = wb.wIndex;

    super.writeSQUndefinedLength(e, vrIndex);

    final eEnd = wb.wIndex;
    assert(e.vfLength + 12 == e.eEnd - e.eStart, '${e.vfLength}, $eEnd - $eStart');
    assert(e.vfLength + 12 == (eEnd - eStart), '${e.vfLength}, $eEnd - $eStart');
    outputOffsets.insertAt(index, eStart, eEnd, e);
  }

  void _writeSQUndefinedLength(SQ e, int vrIndex) {
    log.debug('${wb.wbb} writeSQUndefinedLength $e :${wb.remaining}', 1);
    final eStart = wb.wIndex;
    final index = outputOffsets.reserveSlot;
    super.writeSQUndefinedLength(e, vrIndex);
    pInfo.nUndefinedLengthSequences++;
    outputOffsets.insertAt(index, eStart, wb.wIndex, e);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isLongLengthVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isShortLengthVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;
