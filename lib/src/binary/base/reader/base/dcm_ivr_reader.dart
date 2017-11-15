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

import 'package:dcm_convert/src/binary/base/reader/base/reader_base.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

abstract class IvrReader extends DcmReaderBase {
  final bool isEVR = false;

  /// Creates a new [IvrReader]  where [rb].rIndex = 0.
  IvrReader(ByteData bd, RootDataset rds,
      {String path = '',
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange})
      : super(bd, rds, path, dParams, reUseBD: reUseBD);

  @override
  RootDataset read() {
    cds = rds;
    final fmiBD = readFmi(rds);

    final rdsStart = rb.index;
    readDatasetDefinedLength(rds, rb.rIndex, rb.remaining);
    final rdsLength = rb.index - rdsStart;
    final rdsBD = rb.bd.buffer.asByteData(rdsStart, rdsLength);
    final dsBytes = new RDSBytes(fmiBD, rdsBD);
    rds.dsBytes = dsBytes;
    return rds;
  }

  /// All [Element]s are read by this method.
  @override
  Element readElement() {
    final eStart = rb.rIndex;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrIndex = _lookupIvrVRIndex(code, eStart, tag);

    Element e;
    if (_isIvrDefinedLengthVR(vrIndex)) {
      e = readIvrDefinedLength(code, eStart, vrIndex);
      log.up;
    } else if (_isSequenceVR(vrIndex)) {
      e = readSequence(code, eStart, vrIndex);
      log.up;
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      e = readMaybeUndefined(code, eStart, vrIndex);
      log.up;
    } else {
      return invalidVRIndexError(vrIndex);
    }
    return e;
  }

  int _lookupIvrVRIndex(int code, int eStart, Tag tag) {
    final vr = (tag == null) ? VR.kUN : tag.vr;
    return _vrToIndex(code, vr);
  }

  /// Read an IVR Element (not SQ) with a 32-bit vfLengthField (vlf),
  /// but that cannot have kUndefinedValue.
  Element readIvrDefinedLength(int code, int eStart, int vrIndex) {
    final vlf = rb.uint32;
    assert(vlf != kUndefinedLength);
    return readDefinedLength(code, eStart, vrIndex, vlf);
  }

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element readMaybeUndefined(int code, int eStart, int vrIndex) {
    final vlf = rb.uint32;
    return readMaybeUndefinedLength(code, eStart, vrIndex, vlf);
  }

  @override
  Element readSequence(int code, int eStart, int vrIndex) {
    final vlf = rb.uint32;
    return (vlf == kUndefinedLength)
        ? readUSQ(code, eStart, vlf)
        : readDSQ(code, eStart, vlf);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

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
