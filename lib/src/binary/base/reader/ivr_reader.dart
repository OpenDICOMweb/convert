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
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader_base.dart';
import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/log_read_mixin_base.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

abstract class IvrReader extends DcmReaderBase with LogReadMixinBase {
  @override
  final bool isEvr = false;

  /// Creates a new [IvrReader]  where [rb].rIndex = 0.
  IvrReader(
      ByteData bd, RootDataset rds, String path, DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, dParams, reUseBD);

  IvrReader.from(EvrReader r) : super.from(r);

  @override
  ByteData readFmi() => unsupportedError();

/*
  @override
  RootDataset readRootDataset() {
    if (!isFmiRead) throw 'FMI is not read';
    return super.readRootDataset();
  }
*/

  /// All [Element]s are read by this method.
  @override
  Element readElement() {
    final eStart = rb.index;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrIndex = _lookupIvrVRIndex(code, eStart, tag);

    if (_isIvrDefinedLengthVR(vrIndex))
      return readIvrDefinedLength(code, eStart, vrIndex);
    if (_isSequenceVR(vrIndex)) return readSequence(code, eStart, vrIndex);
    if (_isMaybeUndefinedLengthVR(vrIndex))
      return readMaybeUndefined(code, vrIndex, eStart);
    invalidVRIndex(vrIndex, null, null);
    return null;
  }

  int _lookupIvrVRIndex(int code, int eStart, Tag tag) {
    final vr = (tag == null) ? VR.kUN : tag.vr;
    return _vrToIndex(code, vr);
  }

  int _vrToIndex(int code, VR vr) {
    var vrIndex = vr.index;
    if (_isSpecialVR(vrIndex)) {
      log.info1('-- Changing Special VR ${VR.lookupByIndex(vrIndex)}) to VR.kUN');
      vrIndex = VR.kUN.index;
    }
    return vrIndex;
  }

  /// Read an IVR Element (not SQ) with a 32-bit vfLengthField (vlf),
  /// but that cannot have kUndefinedValue.
  Element readIvrDefinedLength(int code, int eStart, int vrIndex) {
    final vlf = rb.uint32;
    logStartRead(code, vrIndex, eStart, vlf, 'readIvrDefinedLength');
    assert(vlf != kUndefinedLength);
    return _makeIvr(code, vrIndex, eStart, vlf);
  }

  Element _makeIvr(int code, int vrIndex, int eStart, int vlf) {
    assert(vlf != kUndefinedLength);
    rb + vlf;
    final eb = rb.makeIvrEBytes(eStart);
    final e = (code == kPixelData)
        ? makePixelData(code, vrIndex, eb)
        : makeElement(code, vrIndex, eb);
    logEndRead(eStart, e, 'makeIvr');
    return e;
  }

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element readMaybeUndefined(int code, int vrIndex, int eStart) {
    final vlf = rb.uint32;
    logStartRead(code, vrIndex, eStart, vlf, 'readMaybeUndefined');
    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex && isUNSequence(vlf)) {
      print('maybe UNSequence: $vrIndex $vlf');
      final items = readUSQ(code, vrIndex, eStart, vlf);
      return _makeSequence(code, vrIndex, eStart, items);
    }

    if (vlf != kUndefinedLength) return _makeIvr(code, vrIndex, eStart, vlf);

    final fragments = readUndefinedLength(code, eStart, vrIndex, vlf);
    final eb = rb.makeIvrEBytes(eStart);
    final e = (code == kPixelData)
        ? makePixelData(code, vrIndex, eb, fragments: fragments)
        : makeElement(code, vrIndex, eb);
    logEndRead(eStart, e, 'readMaybeUndefined');
    return e;
  }

  @override
  Element readSequence(int code, int eStart, int vrIndex) {
    assert(vrIndex == kSQIndex);
    final vlf = rb.uint32;
    logStartSQRead(code, vrIndex, eStart, vlf, 'readIvrSequence');
    final items = (vlf == kUndefinedLength)
        ? readUSQ(code, vrIndex, eStart, vlf)
        : readDSQ(code, vrIndex, eStart, vlf);
    final e = _makeSequence(code, vrIndex, eStart, items);
    logEndSQRead(eStart, e, 'readIvrSequence');
    return e;
  }

  SQ _makeSequence(int code, int vrIndex, int eStart, List<Item> items) {
    assert(vrIndex == kSQIndex);
    final eb = rb.makeIvrEBytes(eStart);
    return makeSequence(code, eb, cds, items);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
