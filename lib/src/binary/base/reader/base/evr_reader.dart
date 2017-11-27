// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dcm_convert/src/binary/base/reader/base/reader_base.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

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
class EvrReader extends DcmReaderBase {
  /// Creates a new [EvrReader]  where [rb].rIndex = 0.
  EvrReader(ByteData bd, RootDataset rds, String path,
      DecodingParameters dParams, {bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD: reUseBD);

  bool get isEVR => true;

  @override
  ByteData readFmi() => _readFmi();

  @override
  RootDataset evrRead() {
    cds = rds;
    final rdsStart = rb.index;
    final rdsLength = rb.index - rdsStart;
    final rdsBD = rb.bd.buffer.asByteData(rdsStart, rdsLength);
    final dsBytes = new RDSBytes(fmiBD, rdsBD);
    rds.dsBytes = dsBytes;
    return rds;
  }

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element readElement() {
    final eStart = rb.index;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrCode = rb.uint16;
    final vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);
    int newVRIndex;

    // Note: this is only relevant for EVR
    if (tag != null) {
      if (dParams.doCheckVR && !isNotValidVR(code, vrIndex, tag)) {
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
    //TODO: fix order to most common Element type
    if (_isShortVR(vrIndex)) return readEvrShort(code, eStart, vrIndex);
    if (_isSequenceVR(vrIndex)) return readSequence(code, eStart, vrIndex);
    if (_isLongVR(vrIndex)) return readLong(code, eStart, vrIndex);
    if (_isUndefinedLengthVR(vrIndex))
      return readMaybeUndefined(code, eStart, vrIndex);
    //TODO: fix vrErrors in Tag.  Make VR a seperate package
    invalidVRIndex(vrIndex, null, null);
    return null;
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit
  /// Value Field Length field. These Elements may not have
  /// a kUndefinedLength value.
  Element readEvrShort(int code, int eStart, int vrIndex) {
    final vlf = rb.uint16;
    rb + vlf;
    readStartMsg(eStart, vrIndex, code, 'readEvrShort', vlf);
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
    return readDefinedLength(code, eStart, vrIndex, vlf);
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
    return readMaybeUndefinedLength(code, eStart, vrIndex, vlf);
  }

  @override
  Element readMaybeUndefinedLength(int code, int eStart, int vrIndex, int vlf) {
    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex) {
      final e = tryReadUNSequence(code, eStart, vlf);
      if (e != null) return e;
    }
    return (vlf == kUndefinedLength)
        ? readUndefinedLength(code, eStart, vrIndex, vlf)
        : readDefinedLength(code, eStart, vrIndex, vlf);
  }

  /// Read an EVR Sequence.
  @override
  Element readSequence(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    return (vlf == kUndefinedLength)
        ? readUSQ(code, eStart, vlf)
        : readDSQ(code, eStart, vlf);
  }

  // **** Private methods

  int _lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vr = VR.lookupByCode(vrCode);
    if (vr == null) {
      log.debug('${rb.rmm} ${dcm(code)} $eStart ${hex16(vrCode)}');
      rb.warn('VR is Null: vrCode(${hex16(vrCode)}) '
          '${dcm(code)} start: $eStart ${rb.rrr}');
      showNext(rb.rIndex - 4);
    }
    return __vrToIndex(code, vr);
  }

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  ByteData _readFmi() {
    if (!_readPrefix(rb)) {
      rb.index = 0;
      return null;
    }
    final fmiStart = rb.index;
    while (rb.isReadable) {
      final code = rb.peekCode;
      if (code >= 0x00030000) break;
      rds.fmi.add(readElement());
    }
    final fmiEnd = rb.index;

    if (!rb.hasRemaining(dParams.shortFileThreshold - rb.rIndex)) {
      throw new EndOfDataError(
          '_readFmi', 'index: ${rb.rIndex} bdLength: ${rb.lengthInBytes}');
    }

    final ts = rds.transferSyntax;
    if (!system.isSupportedTransferSyntax(ts.asString)) {
      return invalidTransferSyntax(ts);
    }
    if (dParams.targetTS != null && ts != dParams.targetTS)
      return invalidTransferSyntax(ts, dParams.targetTS);

    // Assumes that FMI always starts at rb.index == 0.
    return rb.bd.buffer.asByteData(fmiStart, fmiEnd);
  }

  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
  /// Returns true if a valid Preamble and Prefix where read.
  bool _readPrefix(ReadBuffer rb) {
    if (rb.rIndex != 0) return false;
    return _isDcmPrefixPresent(rb);
  }

/*
  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
  /// Returns true if a valid Preamble and Prefix where read.
  bool readPrefixPInfo(ReadBuffer rb, ParseInfo pInfo) {
    if (rb.rIndex != 0 || rb.lengthInBytes <= 132) return false;
    rb.index = 128;
    return isDcmPrefixPresent(rb);
  }
*/

  /// Read as 32-bit integer. This is faster
  bool _isDcmPrefixPresent(ReadBuffer rb) {
    rb + 128;
    final prefix = rb.uint32;
    if (prefix == kDcmPrefix) {
      return true;
    } else {
      rb.warn('No DICOM Prefix present @${rb.rrr}');
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
      rb.warn('No DICOM Prefix present @${rb.rrr}');
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
    vrIndex >= kVRMaybeUndefinedIndexMin &&
    vrIndex <= kVRMaybeUndefinedIndexMax;

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
