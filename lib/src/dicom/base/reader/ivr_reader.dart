// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/reader/dcm_reader_base.dart';

// ignore_for_file: avoid_positional_boolean_parameters

abstract class IvrReader<V> extends DcmReaderBase<V> {
  @override
  ReadBuffer get rb;

  @override
  ByteData readFmi() => unsupportedError();

  /// All [Element]s are read by this method.
  @override
  Element readElement() {
    final eStart = rb.rIndex;
    final code = rb.readCode();
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
      log.info1('-- Changing Special VR ${vrIdFromIndex(vrIndex)}) to VR.kUN');
      vrIndex = VR.kUN.index;
    }
    return vrIndex;
  }

  /// Read an IVR Element (not SQ) with a 32-bit vfLengthField (vlf),
  /// but that cannot have kUndefinedValue.
  Element readIvrDefinedLength(int code, int eStart, int vrIndex) {
    final vlf = rb.readUint32();
    logStartRead(code, vrIndex, eStart, vlf, 'readIvrDefinedLength');
    assert(vlf != kUndefinedLength);
    return _makeIvr(code, vrIndex, eStart, vlf);
  }

  Element _makeIvr(int code, int vrIndex, int eStart, int vlf) {
    assert(vlf != kUndefinedLength);
    rb.rSkip(vlf);
    final e = (code == kPixelData)
        ? makePixelData(code, vrIndex, rb.bdView(eStart))
        : makeFromByteData(code, vrIndex, rb.bdView(eStart));
    logEndRead(eStart, e, 'makeIvr');
    return e;
  }

  @override
  Element makePixelData(int code, int vrIndex, ByteData bd,
          [TransferSyntax ts, VFFragments fragments]) =>
      IvrElement.makePixelData(code, vrIndex, bd, ts, fragments);

  @override
  Element makeFromByteData(int code, int vrIndex, ByteData bd) =>
      IvrElement.make(code, vrIndex, bd);

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element readMaybeUndefined(int code, int vrIndex, int eStart) {
    final vlf = rb.readUint32();
    logStartRead(code, vrIndex, eStart, vlf, 'readMaybeUndefined');
    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex && isUNSequence(vlf))
      return _readUSQ(code, vrIndex, eStart, vlf);

    if (vlf != kUndefinedLength) return _makeIvr(code, vrIndex, eStart, vlf);

    final fragments = readUndefinedLength(code, eStart, vrIndex, vlf);

    final e = (code == kPixelData)
        ? makePixelData(code, vrIndex, rb.bdView(eStart), rds.transferSyntax, fragments)
        : makeFromByteData(code, vrIndex, rb.bdView(eStart));
    logEndRead(eStart, e, 'readMaybeUndefined');
    return e;
  }

  @override
  Element readSequence(int code, int eStart, int vrIndex) {
    assert(vrIndex == kSQIndex);
    final vlf = rb.readUint32();
    logStartSQRead(code, vrIndex, eStart, vlf, 'readIvrSequence');
    return (vlf == kUndefinedLength)
        ? _readUSQ(code, vrIndex, eStart, vlf)
        : _readDSQ(code, vrIndex, eStart, vlf);
  }

  /// Reads a [kUndefinedLength] Sequence.
  SQ _readUSQ(int code, int vrIndex, int eStart, int vlf) {
    assert(vrIndex == kSQIndex);
    assert(vlf == kUndefinedLength);
    final items = <Item>[];
    //TODO: What the performance cost of not integrating isSequenceDelimiter?
    while (!isSequenceDelimiter()) {
      final item = readItem();
      items.add(item);
    }
    final e = makeSequence(code, rb.bdView(eStart), cds, items);
    logEndSQRead(eStart, e, 'readEvrSequenceULength');
    return e;
  }

  @override
  SQ makeSequence(int code, ByteData bd, Dataset cds, List<Item> items) =>
      IvrElement.makeSequence(code, bd, cds, items);

  /// Reads a defined [vfl].
  SQ _readDSQ(int code, int vrIndex, int eStart, int vfl) {
    assert(vrIndex == kSQIndex);
    assert(vfl != kUndefinedLength);
    final items = <Item>[];
    final eEnd = rb.rIndex + vfl;

    while (rb.rIndex < eEnd) {
      final item = readItem();
      items.add(item);
    }
    final end = rb.rIndex;
    assert(eEnd == end, '$eEnd == $end');
    final e = makeSequence(code, rb.bdView(eStart), cds, items);
    logEndSQRead(eStart, e, 'readEvrSequenceDLength');
    return e;
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
