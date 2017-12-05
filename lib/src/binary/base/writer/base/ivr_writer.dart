// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/writer/base/dcm_writer_base.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

class IvrWriter extends DcmWriterBase {
  @override
  final bool isEvr = false;

  IvrWriter(RootDataset rds,
      {String path,
      TransferSyntax outputTS,
      int minLength,
      bool reUseBD = true,
      EncodingParameters eParams = EncodingParameters.kNoChange,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets})
      : super(rds,
            path: path,
            eParams: eParams,
            outputTS: outputTS,
            minLength: minLength,
            reUseBD: reUseBD,
            elementOffsetsEnabled: elementOffsetsEnabled,
            inputOffsets: inputOffsets);

  @override
  Uint8List writeRootDataset(RootDataset rds) {
    final dsStart = wb.index;
    log.debug('${wb.wbb} _writeIvrRootDataset $rds :${wb.remaining}', 1);

    // ignore: prefer_forEach
    for (var e in rds.elements) {
      writeElement(e);
    }

    log.debug('${wb.wee} _writeIvrRootDataset  :${wb.remaining}', -1);
    return wb.toUint8List(dsStart, wb.index - dsStart);
  }

  @override
  void writeElement(Element e) {
    elementCount++;
    log.debug('${wb.wbb} _writeIvrElement $e :${wb.remaining}', 1);
    final eStart = wb.wIndex;
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      vrIndex = VR.kUN.index;
      wb.warn('** vrIndex changed to VR.kUN.index');
    }

    if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeSimpleIvr(e);
    } else if (_isSequenceVR(vrIndex)) {
      _writeIvrSQ(e);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeIvrMaybeUndefined(e);
    } else if (_isSpecialVR(vrIndex)) {
      _writeIvrMaybeUndefined(e);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }
//  print('Level: ${log.indenter.level}');
    log.debug('${wb.wee} _writeIvrElement ${e.dcm} ${e.keyword}');
    pInfo.nElements++;
    doEndOfElementStats(eStart, wb.wIndex, e);
  }

  void _writeSimpleIvr(Element e) {
    log.debug('${wb.wbb} writeSimpleIvr $e :${wb.remaining}', 1);
    _reallyWriteIvrDefinedLength(e);
  }

  void _writeIvrMaybeUndefined(Element e) {
    log.debug('${wb.wbb} writeIvrMaybeUndefined $e :${wb.remaining}', 1);
    pInfo.nMaybeUndefinedElements++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _reallyWriteIvrUndefinedLength(e)
        : _reallyWriteIvrDefinedLength(e);
  }

  void _writeIvrSQ(SQ e) {
    pInfo.nSequences++;
    if (e.isPrivate) pInfo.nPrivateSequences++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeIvrSQUndefinedLength(e)
        : _writeIvrSQDefinedLength(e);
  }

  void _writeIvrSQDefinedLength(SQ e) {
    log.debug('${wb.wbb} _writeIvrSQDefined $e :${wb.remaining}', 1);
    pInfo.nDefinedLengthSequences++;
    _reallyWriteIvrDefinedLength(e);
  }

  void _writeIvrSQUndefinedLength(SQ e) {
    log.debug('${wb.wbb} _writeIvrSQUndefined $e :${wb.remaining}', 1);
    pInfo.nUndefinedLengthSequences++;
    _reallyWriteIvrUndefinedLength(e);
  }

  void _reallyWriteIvrDefinedLength(Element e) {
    assert(e.vfLengthField != kUndefinedLength);
    if (e.code == kPixelData) {
      updatePInfoPixelData(e);
    } else {
      log.debug('${wb.wmm} _writeSimpleIvr $e :${wb.remaining}', 1);
    }
    wb
      ..code(e.code)
      ..uint32(e.vfLength);
    _writeValueField(e);
    pInfo.nLongElements++;
  }

  void _reallyWriteIvrUndefinedLength(Element e) {
    assert(e.vfLengthField == kUndefinedLength);
    if (e.code == kPixelData) {
      updatePInfoPixelData(e);
    } else {
      log.debug('${wb.wbb} writeIvrUndefined $e :${wb.remaining}', 1);
    }
    wb
      ..code(e.code)
      ..uint32(kUndefinedLength);
    _writeValueField(e);
    wb.uint32(kSequenceDelimitationItem32BitLE);
    if (e.code == kPixelData) pInfo.pixelDataEnd = wb.wIndex;
    pInfo.nUndefinedLengthElements++;
  }

  void _writeValueField(Element e) {
    final bytes = e.vfBytes;
    // print('bytes.length: ${bytes.lengthInBytes}');
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

bool _isEvrLongLengthVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortLengthVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
