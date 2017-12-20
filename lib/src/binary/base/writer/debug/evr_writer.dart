// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/writer/evr_writer.dart';
import 'package:dcm_convert/src/binary/base/writer/debug/log_write_mixin.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

class LogEvrWriter extends EvrWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  LogEvrWriter(RootDataset rds, EncodingParameters eParams, int minBDLength,
      bool reUseBD, this.inputOffsets)
      : pInfo = new ParseInfo(rds),
        outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        elementCount = -1,
        super(rds, eParams, minBDLength, reUseBD);

  @override
  void writeElement(Element e) {
    logStartWrite(wb.index, e, 'writeEvrElement');
    elementCount++;
    final eStart = wb.wIndex;
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      wb.warn('** vrIndex changed to VR.kUN.index');
    }

    log.debug('${wb.wbb} #$elementCount writeEvrElement $e :${wb.remaining}', 1);
    if (_isEvrShortLengthVR(vrIndex)) {
      writeShort(e);
    } else if (_isEvrLongLengthVR(vrIndex)) {
      writeLong(e);
    } else if (_isSequenceVR(vrIndex)) {
      writeSequence(e);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      writeMaybeUndefined(e);
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
    log.debug('${wb.wee} #$elementCount writeEvrElement ${e.dcm} ${e.keyword}', -2);
  }

  @override
  void writeShort(Element e) {
    log.debug('${wb.wbb} writeShortEvr $e :${wb.remaining}', 1);
    super.writeShortEvr(e);
    pInfo.nShortElements++;
  }

  /// Write a non-Sequence _defined length_ Element.
  @override
  void writeLong(Element e) {
    log.debug('${wb.wbb} writeLongEvrDefinedLength $e :${wb.remaining}', 1);
    super.writeLongEvrDefinedLength(e);
    pInfo.nLongElements++;
  }

  @override
  void writeMaybeUndefined(Element e) {
    log.debug('${wb.wbb} writeEvrMaybeUndefined $e :${wb.remaining}', 1);

    super.writeEvrMaybeUndefined(e);

    pInfo.nMaybeUndefinedElements++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeLongEvrUndefinedLength(e)
        : writeLong(e);
  }

  void _writeLongEvrUndefinedLength(Element e) {
    log.debug('${wb.wmm} writeEvrUndefined $e :${wb.remaining}');

    super.writeLongEvrUndefinedLength(e);

    pInfo.nUndefinedLengthElements++;
  }

  @override
  void writeSequence(SQ e) {
    pInfo.nSequences++;
    if (e.isPrivate) pInfo.nPrivateSequences++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeEvrSQUndefinedLength(e)
        : _writeEvrSQDefinedLength(e);
  }

  void _writeEvrSQDefinedLength(SQ e) {
    log.debug('${wb.wbb} writeEvrSQDefinedLength $e :${wb.remaining}', 1);
    final index = outputOffsets.reserveSlot;
    pInfo.nDefinedLengthSequences++;
    final eStart = wb.index;

    super.writeEvrSQUndefinedLength(e);

    final eEnd = wb.wIndex;
    assert(e.vfLength + 12 == e.eEnd - e.eStart, '${e.vfLength}, $eEnd - $eStart');
    assert(e.vfLength + 12 == (eEnd - eStart), '${e.vfLength}, $eEnd - $eStart');
    outputOffsets.insertAt(index, eStart, eEnd, e);
  }

  void _writeEvrSQUndefinedLength(SQ e) {
    log.debug('${wb.wbb} writeEvrSQUndefinedLength $e :${wb.remaining}', 1);
    final eStart = wb.index;
    final index = outputOffsets.reserveSlot;
    super.writeEvrSQUndefinedLength(e);
    pInfo.nUndefinedLengthSequences++;
    outputOffsets.insertAt(index, eStart, wb.index, e);
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
