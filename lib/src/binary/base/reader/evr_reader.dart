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
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader_base.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';

// ignore_for_file: avoid_positional_boolean_parameters

//Urgent Jim: add to EvrULength at appropriate places
// Reader axioms
// 1. eStart is always the first byte of the Element being read and eEnd is always
//    the end of the Element be
// 2. The read index (rIndex) should always be at the last place read,
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
  @override
  bool isEvr = true;

  /// Creates a new [EvrReader]  where [rb].rIndex = 0.
  EvrReader(
      ByteData bd, RootDataset rds, String path, DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, dParams, reUseBD) {
    print('EvrReader: $rds');
  }

  @override
  int readFmi() {
    //TODO: make method an invalidReadIndex(int index)
    if (rb.index != 0) throw 'InvalidReadBufferIndex: ${rb.index}';
    return _readFmi();
  }

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element readElement() {
    final eStart = rb.index;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrCode = rb.uint16;
    print('@$eStart ${dcm(code)} ${hex16(vrCode)}');
    var vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);

    // Note: this is only relevant for EVR
    if (tag != null) {
      if (dParams.doCheckVR && isNotValidVR(code, vrIndex, tag)) {
        final vr = VR.lookupByCode(vrCode);
        log.error('VR $vr is not valid for $tag');
      }

      if (dParams.doCorrectVR) {
        //Urgent: implement replacing the VR, but must be after parsing
        final newVRIndex = correctVR(code, vrIndex, tag);
        if (newVRIndex != vrIndex) {
          final newVR = tag.vr;
          log.info1('** Changing VR from $vrIndex to $newVR');
          vrIndex = newVR.index;
        }
      }
    }

    if (_isShortVR(vrIndex)) return readShort(code, vrIndex, eStart);
    if (_isLongVR(vrIndex)) return readLong(code, vrIndex, eStart);
    if (_isSequenceVR(vrIndex)) return readSequence(code, vrIndex, eStart);
    if (_isUndefinedLengthVR(vrIndex)) return readMaybeUndefined(code, vrIndex, eStart);
    invalidVRIndex(vrIndex, null, null);
    return null;
  }

  int _lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vr = VR.lookupByCode(vrCode);
    if (vr == null) {
      rb.warn('Null VR: vrCode(${hex16(vrCode)}, $vrCode) ${dcm(code)} start: $eStart');
    }
    return __vrToIndex(code, vr);
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit Value Field Length field.
  /// These Elements can not have an kUndefinedLength value.
  Element readShort(int code, int vrIndex, int eStart) {
    final vlf = rb.uint16;
    if (vlf.isOdd) print('Odd vlf: $vlf');
    rb + vlf;
    logStartRead(code, vrIndex, eStart, vlf, 'readEvrShort');
    final eb = rb.makeEvrShortEBytes(eStart, vrIndex);
    final e = makeElement(code, vrIndex, eb);
    logEndRead(eStart, e, 'readEvrShort');
    return e;
  }

  /// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// which cannot have the value kUndefinedValue.
  ///
  /// Reads one of OD, OF, OL, UC, UR, or UT.
  Element readLong(int code, int vrIndex, int eStart) {
    rb + 2;
    final vlf = rb.uint32;
    logStartRead(code, vrIndex, eStart, vlf, 'readEvrLong');
    return _makeLong(code, vrIndex, eStart, vlf);
  }

  Element _makeLong(int code, int vrIndex, int eStart, int vlf) {
    assert(vlf != kUndefinedLength);
    rb + vlf;
    final eb = rb.makeEvrLongEBytes(eStart, vrIndex);
    final e = (code == kPixelData)
        ? makePixelData(code, vrIndex, eb)
        : makeElement(code, vrIndex, eb);
    logEndRead(eStart, e, 'readEvrLong');
    return e;
  }

  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  ///
  //  If the VR is UN then it may be a Sequence.  If it is a Sequence, it will
  //  start with either a kItem delimiter or if it is an empty undefined length
  //  Sequence it will start with a kSequenceDelimiter.
  Element readMaybeUndefined(int code, int vrIndex, int eStart) {
    rb + 2;
    final vlf = rb.uint32;
    logStartRead(code, vrIndex, eStart, vlf, 'readEvrMaybeUndefined');
    if (vlf != kUndefinedLength) return _makeLong(code, vrIndex, eStart, vlf);

    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex && isUNSequence(vlf))
      return _readUSQ(code, vrIndex, eStart, vlf);

    final fragments = readUndefinedLength(code, eStart, vrIndex, vlf);
    final eb = rb.makeIvrULengthEBytes(eStart, vrIndex);
    final e = (code == kPixelData)
        ? makePixelData(code, vrIndex, eb, fragments: fragments)
        : makeElement(code, vrIndex, eb);
    logEndRead(eStart, e, 'readEvrMaybeUndefined');
    return e;
  }

  /// Read an EVR Sequence.
  @override
  SQ readSequence(int code, int vrIndex, int eStart) {
    assert(vrIndex == kSQIndex);
    rb + 2;
    final vlf = rb.uint32;
    logStartSQRead(code, vrIndex, eStart, vlf, 'readEvrSequence');
    return (vlf == kUndefinedLength)
        ? _readUSQ(code, vrIndex, eStart, vlf)
        : _readDSQ(code, vrIndex, eStart, vlf);
  }

  /// Reads a [kUndefinedLength] Sequence.
  SQ _readUSQ(int code, int vrIndex, int eStart, int vlf) {
    assert(vrIndex == kSQIndex);
    assert(vlf == kUndefinedLength);
    final items = <Item>[];
    while (!isSequenceDelimiter()) {
      final item = readItem();
      items.add(item);
    }
    final eb = rb.makeEvrULengthEBytes(eStart, vrIndex);
    final e = makeSequence(code, eb, cds, items);
    logEndSQRead(eStart, e, 'readEvrSequenceULength');
    return e;
  }

  /// Reads a defined [vfl].
  SQ _readDSQ(int code, int vrIndex, int eStart, int vfl) {
    assert(vrIndex == kSQIndex);
    assert(vfl != kUndefinedLength);
    final items = <Item>[];
    final eEnd = rb.index + vfl;
    print('vfl: $vfl eEnd: $eEnd');

    while (rb.index < eEnd) {
      final item = readItem();
      items.add(item);
    }
    final end = rb.index;
    assert(eEnd == end, '$eEnd == $end');
    final eb = rb.makeEvrLongEBytes(eStart, vrIndex);
    final e = makeSequence(code, eb, cds, items);
    logEndSQRead(eStart, e, 'readEvrSequenceDLength');
    return e;
  }

/*
  SQ _readSequenceDLength(int code, int vrIndex, int eStart, int vlf) {
    final items = readDSQ(code, vrIndex, eStart, vlf);
    final eb = rb.makeEvrLongEBytes(eStart);
    final e = makeSequence(code, eb, cds, items);
    logEndSQRead(eStart, e, 'readEvrSequenceDLength');
    return e;
  }

  SQ _readSequenceULength(int code, int vrIndex, int eStart, int vlf) {
    final items = readUSQ(code, vrIndex, eStart, vlf);
    final eb = rb.makeEvrULengthEBytes(eStart);
    final e = makeSequence(code, eb, cds, items);
    logEndSQRead(eStart, e, 'readEvrSequenceULength');
    return e;
  }
*/

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  int _readFmi() {
    rds.preamble = rb.toByteData(0, 132);
    if (!_readPrefix(rb)) {
      rb.index = 0;
      return -1;
    }
    assert(rb.index == 132, 'Non-Prefix start index: ${rb.index}');
    while (rb.isReadable) {
      final code = rb.peekCode;
      if (code >= 0x00030000) break;
      final e = readElement();
      rds.fmi.add(e);
    }

    if (!rb.hasRemaining(dParams.shortFileThreshold - rb.index)) {
      throw new EndOfDataError(
          '_readFmi', 'index: ${rb.index} bdLength: ${rb.lengthInBytes}');
    }

    final ts = rds.transferSyntax;
    log.info1('TS: $ts');
    final sopClass = rds.sopClass;
    log.info1('SopClass: $sopClass');
    if (!system.isSupportedTransferSyntax(ts.asString)) {
      return invalidTransferSyntax(ts);
    }
    if (dParams.targetTS != null && ts != dParams.targetTS)
      return invalidTransferSyntax(ts, dParams.targetTS);

    return rb.index;
  }

  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
  /// Returns true if a valid Preamble and Prefix where read.
  bool _readPrefix(ReadBuffer rb) {
    if (rb.index != 0) return false;
    return _isDcmPrefixPresent(rb);
  }

  /// Read as 32-bit integer. This is faster
  bool _isDcmPrefixPresent(ReadBuffer rb) {
    rb + 128;
    final prefix = rb.uint32;
    if (prefix == kDcmPrefix) {
      return true;
    } else {
      rb.warn('No DICOM Prefix present');
      return false;
    }
  }

  // *** This is an older/slower version, but keep for debugging.
  /// Read as ASCII String
  static bool isAsciiPrefixPresent(ReadBuffer rb) {
    final chars = rb.readUint8View(4);
    final prefix = ASCII.decode(chars);
    if (prefix == 'DICM') {
      return true;
    } else {
      rb.warn('No DICOM Prefix present');
      return false;
    }
  }

  // **** Static Interface if implemented by subclasses.
  // static RootDataset readInstance(ByteData bd, RootDataset rds);

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