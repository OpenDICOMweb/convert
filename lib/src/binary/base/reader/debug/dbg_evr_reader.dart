// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dcm_convert/src/binary/base/reader/base/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/debug/debug_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

abstract class DbgEvrReader extends EvrReader with DbgMixin {
  /// Creates a new [EvrReader]  where [rb].rIndex = 0.
  DbgEvrReader(ByteData bd, RootDataset rds,
      {String path = '',
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange})
      : super(bd, rds, path, dParams, reUseBD);

  @override
  ParseInfo get pInfo;

  @override
  RootDataset read() {
    if (pInfo.wasShortFile) return shortFileError();
    dbgDSReadStart('read');
    final rds = super.read();
    dbgDSReadEnd('read', rds);
    return rds;
  }

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element readElement() {
    final eStart = rb.rIndex;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrCode = rb.uint16;
    final vrIndex = __lookupEvrVRIndex(code, eStart, vrCode);
    int newVRIndex;
    dbgReadStart(eStart, vrIndex, code, 'EVR readElement');
    final e = super.readElement();
    elementCount++;

    // Note: this is only relevant for EVR
    if (tag != null) {
      if (dParams.doCheckVR && isNotValidVR(code, vrIndex, tag)) {
        final vr = VR.lookupByCode(vrCode);
        log.error('VR $vr is not valid for $tag');
      }

      if (dParams.doCorrectVR) {
        final oldIndex = vrIndex;
        //Urgent: implement replacing the VR, but must be after parsing
        newVRIndex = correctVR(code, vrIndex, tag);
        if (vrIndex != oldIndex) {
          final oldVR = VR.lookupByCode(vrCode);
          final newVR = tag.vr;
          log.info1('** Changing VR from $oldVR to $newVR');
        }
      }
    }

    dbgReadEnd(eStart, e);
    return e;
  }

  int __lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vr = VR.lookupByCode(vrCode);
    if (vr == null) {
      log.debug('${rb.rmm} ${dcm(
	code)} $eStart ${hex16(
	vrCode)}');
      rb.warn('VR is Null: vrCode(${hex16(
	vrCode)}) '
          '${dcm(
	code)} start: $eStart ${rb.rrr}');
      showNext(rb.rIndex - 4);
    }
    return __vrToIndex(code, vr);
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit
  /// Value Field Length field. These Elements may not have
  /// a kUndefinedLength value.
  @override
  Element readEvrShort(int code, int eStart, int vrIndex) {
    super.readEvrShort(eStart, vrIndex, code);
    final vlf = rb.uint16;
    rb + vlf;
    dbgReadStart(eStart, vrIndex, code, 'readEvrShort', vlf);

    pInfo.nShortElements++;
    return makeElement(code, eStart, vrIndex, vlf, EvrShort.make);
  }

  /// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// but that cannot have the value kUndefinedValue.
  ///
  /// Reads one of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
  Element readEvrLong(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    assert(vlf != kUndefinedLength);
    return readDefinedLength(code, eStart, vrIndex, vlf);
  }

  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  //  If the Element if UN then it maybe a Sequence.  If it is it will
  //  start with either a kItem delimiter or if it is an empty undefined
  //  Sequence it will start with a kSequenceDelimiter.
  @override
  Element readMaybeUndefined(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    return readMaybeUndefinedLength(code, eStart, vrIndex, vlf);
  }

  /// Read and EVR Sequence.
  Element readEvrSQ(int code, int eStart) {
    rb + 2;
    final vlf = rb.uint32;
    return readSequence(code, eStart, vlf);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin &&
    vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

int __vrToIndex(int code, VR vr) {
  var vrIndex = vr.index;
  if (_isSpecialVR(vrIndex)) {
    log.info1('-- Changing Special VR ${VR.lookupByIndex(vrIndex)}) to VR.kUN');
    vrIndex = VR.kUN.index;
  }
  return vrIndex;
}
