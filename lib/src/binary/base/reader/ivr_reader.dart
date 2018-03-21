// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/dcm_reader_base.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

abstract class IvrReader<V> extends DcmReaderBase {
  @override
  ReadBuffer get rb;
  DecodingParameters get dParams;

  @override
  int readFmi(int eStart) => unsupportedError();

  /// All [Element]s are read by this method.
  @override
  Element readElement() {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final tag = checkCode(code, eStart);
    final vrIndex = _lookupIvrVRIndex(code, eStart, tag);

    if (_isIvrDefinedLengthVR(vrIndex))
      return _readDefinedLength(code, eStart, vrIndex);
    if (_isSequenceVR(vrIndex)) return _readSequence(code, eStart, vrIndex);
    if (_isMaybeUndefinedLengthVR(vrIndex))
      return _readMaybeUndefined(code, vrIndex, eStart);
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
  Element _readDefinedLength(int code, int eStart, int vrIndex) {
    final vlf = rb.readUint32();
    assert(vlf != kUndefinedLength);
    return _makeIvr(code, vrIndex, eStart, vlf);
  }

  Element _makeIvr(int code, int vrIndex, int eStart, int vlf) {
    assert(vlf != kUndefinedLength);
    rb.rSkip(vlf);
    final bytes = rb.subbytes(eStart, rb.index);
    final e = (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex)
        : makeFromBytes(code, bytes, vrIndex);
//    logEndRead(eStart, e, 'makeIvr');
    return e;
  }

  @override
  Element makePixelData(int code, Bytes bd, int vrIndex,
          [TransferSyntax ts, VFFragments fragments]) =>
      IvrElement.makePixelData(code, bd, vrIndex, ts, fragments);

  @override
  Element makeFromBytes(int code, Bytes bd, int vrIndex) =>
      IvrElement.make(code, bd, vrIndex);

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element _readMaybeUndefined(int code, int vrIndex, int eStart) {
    final vlf = rb.readUint32();
    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex && isUNSequence(vlf))
      return _readUSQ(code, vrIndex, eStart, vlf);

    if (vlf != kUndefinedLength) return _makeIvr(code, vrIndex, eStart, vlf);

    final fragments = readUndefinedLength(code, eStart, vrIndex, vlf);
    final bd = rb.subbytes(eStart, rb.index);
    final e = (code == kPixelData)
        ? makePixelData(code, bd, vrIndex, rds.transferSyntax, fragments)
        : makeFromBytes(code, bd, vrIndex);
//    logEndRead(eStart, e, 'readMaybeUndefined');
    return e;
  }

  @override
  Element readSequence(int code, int eStart, int vrIndex) =>
      _readSequence(code, eStart, vrIndex);

  Element _readSequence(int code, int eStart, int vrIndex) {
    assert(vrIndex == kSQIndex);
    final vlf = rb.readUint32();
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
    final e = makeSequence(
      code,
      cds,
      items,
      rb.subbytes(eStart, rb.index),
    );
    return e;
  }

  @override
  SQ makeSequence(int code, Dataset cds, List<Item> items, [Bytes bd]) =>
      IvrElement.makeSequence(code, cds, items, bd);

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
    final e = makeSequence(code, cds, items, rb.asBytes(eStart, rb.index));
    return e;
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin &&
    vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;
