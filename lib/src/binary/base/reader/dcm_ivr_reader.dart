// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';

abstract class IvrReader extends EvrReader {
  final bool isEVR = false;

  /// Creates a new [EvrReader]  where [rb].rIndex = 0.
  IvrReader(ByteData bd, RootDataset rds) : super(bd, rds);

  @override
  RootDataset read() {
    cds = rds;
    readRootDataset(readElement);
    return rds;
  }

  /// All [Element]s are read by this method.
  @override
  Element readElement() {
    final eStart = rb.rIndex;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrIndex = __lookupIvrVRIndex(code, eStart, tag);

    Element e;
    if (_isIvrDefinedLengthVR(vrIndex)) {
      e = _readIvrDefinedLength(code, eStart, vrIndex);
      log.up;
    } else if (_isSequenceVR(vrIndex)) {
      e = _readIvrSQ(code, eStart);
      log.up;
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      e = readIvrMaybeUndefinedLength(code, eStart, vrIndex);
      log.up;
    } else {
      return invalidVRIndexError(vrIndex);
    }
    return e;
  }

  int __lookupIvrVRIndex(int code, int eStart, Tag tag) {
    final vr = (tag == null) ? VR.kUN : tag.vr;
    return _vrToIndex(code, vr);
  }

  /// Read an IVR Element (not SQ) with a 32-bit vfLengthField (vlf),
  /// but that cannot have kUndefinedValue.
  Element _readIvrDefinedLength(int code, int eStart, int vrIndex) {
    final vlf = rb.uint32;
    assert(vlf != kUndefinedLength);
    return super.readDefinedLength(code, eStart, vrIndex, vlf, Ivr.make);
  }

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element readIvrMaybeUndefinedLength(int code, int eStart, int vrIndex) {
    final vlf = rb.uint32;
    return super
        .readMaybeUndefinedLength(code, eStart, vrIndex, vlf, Ivr.make, readElement);
  }

  Element _readIvrSQ(int code, int eStart) {
    final vlf = rb.uint32;
    return super.readSQ(code, eStart, vlf, Ivr.make, readElement);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isNormalVR(int vrIndex) =>
    vrIndex >= kVRNormalIndexMin && vrIndex <= kVRNormalIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

final String kItemAsString = hex32(kItem32BitLE);

int _vrToIndex(int code, VR vr) {
  var vrIndex = vr.index;
  if (_isSpecialVR(vrIndex)) {
    log.info1('-- Changing Special VR ${VR.lookupByIndex(vrIndex)}) to VR.kUN');
    vrIndex = VR.kUN.index;
  }
  return vrIndex;
}
