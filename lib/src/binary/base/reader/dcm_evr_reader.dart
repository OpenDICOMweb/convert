// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

import 'package:dcm_convert/src/binary/base/reader/reader_base.dart';

// Reader axioms
// 1. The read index (rIndex) should always be at the last place read,
//    and the end of the value field should be calculated by subtracting
//    the length of the delimiter (and delimiter length), which is 8 bytes.
//
// 2. For non-sequence Elements with undefined length (kUndefinedLength)
//    the Value Field Length (vfLength) of a non-Sequence Element.
//    The read index rIndex is left at the end of the Element Delimiter.
//
// 3. [_finishReadElement] is only called from [readEvrElement] and
//    [readIvrElement].

/// A [Converter] for [Uint8List]s containing a [Dataset] encoded in the
/// application/dicom media type.
///
/// _Notes_:
/// 1. Reads and returns the Value Fields as they are in the data.
///  For example DcmReader does not trim whitespace from strings.
///  This is so they can be written out byte for byte as they were
///  read. and a byte-wise comparator will find them to be equal.
/// 2. All String manipulation should be handled by the containing
///  [Element] itself.
/// 3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
abstract class EvrReader extends DcmReaderBase {
  final bool isEVR = true;

  /// Creates a new [EvrReader]  where [rb].rIndex = 0.
  EvrReader(ByteData bd, RootDataset rds) : super(bd, rds);

  @override
  RootDataset read() {
    cds = rds;
    final fmiBD = readFmi(rds);
    if (fmiBD == null) return null;

//      return (rds.isEvr) ? EvrReader.readInstance(rds) : IvrReader(rds);
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
    if (_isShortVR(vrIndex)) return readShort(code, eStart, vrIndex);
    if (_isSequenceVR(vrIndex)) return readEvrSQ(code, eStart);
    if (_isLongVR(vrIndex)) return readLong(code, eStart, vrIndex);
    if (_isUndefinedLengthVR(vrIndex)) return readMaybeUndefined(code, eStart, vrIndex);

    return invalidVRIndexError(vrIndex);
  }

  int __lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vr = VR.lookupByCode(vrCode);
    if (vr == null) {
      log.debug('${rb.rmm} ${dcm(code)} $eStart ${hex16(vrCode)}');
      rb.warn('VR is Null: vrCode(${hex16(vrCode)}) '
          '${dcm(code)} start: $eStart ${rb.rrr}');
      showNext(rb.rIndex - 4);
    }
    return __vrToIndex(code, vr);
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit
  /// Value Field Length field. These Elements may not have
  /// a kUndefinedLength value.
  Element readShort(int code, int eStart, int vrIndex) {
    final vlf = rb.uint16;
    rb + vlf;
    return makeElement(code, eStart, vrIndex, vlf, EvrShort.make);
  }

  /// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// but that cannot have the value kUndefinedValue.
  ///
  /// Reads one of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
  Element readLong(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    assert(vlf != kUndefinedLength);
    return readDefinedLength(code, eStart, vrIndex, vlf, EvrLong.make);
  }

  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  //  If the Element if UN then it maybe a Sequence.  If it is it will
  //  start with either a kItem delimiter or if it is an empty undefined
  //  Sequence it will start with a kSequenceDelimiter.
  Element readMaybeUndefined(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    return readMaybeUndefinedLength(
        code, eStart, vrIndex, vlf, EvrLong.make, readElement);
  }

  /// Read an EVR Sequence.
  Element readEvrSQ(int code, int eStart) {
    rb + 2;
    final vlf = rb.uint32;
    return (vlf == kUndefinedLength)
        ? readUSQ(code, eStart, vlf, EvrLong.make, readElement)
        : readDSQ(code, eStart, vlf, EvrLong.make, readElement);
  }

  static RootDataset readFMI(ByteData bd, RootDataset rds) {}

  static RootDataset readInstance(ByteData bd, RootDataset rds) {}
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

int __vrToIndex(int code, VR vr) {
  var vrIndex = vr.index;
  if (_isSpecialVR(vrIndex)) {
    log.info1('-- Changing Special VR ${VR.lookupByIndex(vrIndex)}) to VR.kUN');
    vrIndex = VR.kUN.index;
  }
  return vrIndex;
}
