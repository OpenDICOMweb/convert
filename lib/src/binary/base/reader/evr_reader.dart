// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/dcm_reader_base.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/errors.dart';

// ignore_for_file: avoid_positional_boolean_parameters, only_throw_errors

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

bool doConvertUNSequences = false;

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
abstract class EvrReader<V> extends DcmReaderBase {
  @override
  ReadBuffer get rb;
  DecodingParameters get dParams;

  @override
  int readFmi(int eStart) {
    //TODO: make method an invalidReadIndex(int index)
    if (rb.rIndex != 0) throw 'InvalidReadBufferIndex: ${rb.rIndex}';
    return _readFmi();
  }

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element readElement() {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final group = code >> 16;
    final vrCode = rb.readUint16();
    var vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);

    Element e;
    if (_isShortVR(vrIndex)) {
      e = readShort(code, vrIndex, eStart);
    } else if (_isLongVR(vrIndex)) {
      e = readLongDefinedLength(code, vrIndex, eStart);
    } else if (_isSequenceVR(vrIndex)) {
      e = readSequence(code, vrIndex, eStart);
    } else if (_isUndefinedLengthVR(vrIndex)) {
      e = readMaybeUndefined(code, vrIndex, eStart);
    }
    if (e == null) return invalidVRIndex(vrIndex, null, null);

    Tag tag;
    if (group.isEven) {
      _group = -1;
      tag = PTag.lookupByCode(code, vrIndex);
    } else {
      tag = _getPrivateTag(code, vrIndex, group, e);
    }

    // Note: this is only relevant for EVR
    if (tag != null) {
      if (dParams.doCheckVR && isNotValidVR(code, vrIndex, tag)) {
        final vr = vrIdFromIndex(vrIndex);
        log.error('**** VR $vr is not valid for $tag');
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
    return e;
  }

  int _group;
  int _subgroup;
  Map<int, PCTag> _creators;
  PCTag _creator;

  Tag _getPrivateTag(int code, int vrIndex, int group, Element e) {
    assert(group.isOdd);
    if (_group == -1) {
      _group = group;
      _subgroup = 0;
      _creators = <int, PCTag>{};
    }

    final elt = code & 0xFFFF;

    if (elt == 0) return new GroupLengthPrivateTag(code, vrIndex);
    if (elt < 0x10) return new IllegalPrivateTag(code, vrIndex);
    if ((elt >= 0x10) && (elt <= 0xFF)) {
      // Private Creator - might not be LO
      final subgroup = elt & 0xFF;

      String token;
      if (vrIndex == kLOIndex) {
        if (e.isEmpty) {
          token = 'Creator w/o token';
        } else {
          token = e.value;
        }
      } else {
        token = ascii.decode(e.vfBytes, allowInvalid: true).trimRight();
      }

      final tag = PCTag.make(code, vrIndex, token);
      _creators[subgroup] = tag;
      return tag;
    }
    if ((elt > 0x00FF) && (elt <= 0xFFFF)) {
      // Private Data
      final subgroup = (elt & 0xFF00) >> 8;
      if (subgroup != _subgroup) {
        _creator = _creators[subgroup];
        _subgroup = subgroup;
      }
      return PDTag.make(code, vrIndex, _creator);
    }
    // This should never happen
    return invalidTagCode(code);
  }

  //TODO: speed this up
  int _lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vrIndex = vrIndexFromCode(vrCode);
    if (vrIndex == null) {
      log.warn('Null VR: vrCode(${hex16(vrCode)}, $vrCode) '
          '${dcm(code)} start: $eStart');
    }
    if (_isSpecialVR(vrIndex)) {
      log.info('-- Changing (${hex32(code)}) with Special VR '
          '${vrIdFromIndex(vrIndex)}) to VR.kUN');
      return VR.kUN.index;
    }
    if (Tag.isPCCode(code) && (vrIndex != kLOIndex && vrIndex != kUNIndex)) {
      log.warn('** Invalid Private Creator (${hex32(code)}) '
          '${vrIdFromIndex(vrIndex)}($vrIndex) should be VR.kLO');
    }
    return vrIndex;
  }

  @override
  Element makeFromBytes(int code, Bytes bd, int vrIndex) =>
      EvrElement.make(code, bd, vrIndex);

  /// Read a Short EVR Element, i.e. one with a 16-bit Value Field Length field.
  /// These Elements can not have an kUndefinedLength value.
  Element readShort(int code, int vrIndex, int eStart) {
    final vlf = rb.readUint16();
    if (vlf.isOdd) log.error('Odd vlf: $vlf');
//    logStartRead(code, vrIndex, eStart, vlf, 'readEvrShort');

    rb.rSkip(vlf);
    return makeFromBytes(code, rb.subbytes(eStart, rb.index), vrIndex);
  }

  /// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// which cannot have the value kUndefinedValue.
  ///
  /// Reads one of OD, OF, OL, UC, UR, or UT.
  Element readLongDefinedLength(int code, int vrIndex, int eStart) {
    rb.rSkip(2);
    final vlf = rb.readUint32();
//    logStartRead(code, vrIndex, eStart, vlf, 'readEvrLong');
    return _makeLong(code, vrIndex, eStart, vlf);
  }

  /// Returns an EVR Element with a long Value Field
  Element _makeLong(int code, int vrIndex, int eStart, int vlf) {
    assert(vlf != kUndefinedLength);
    rb.rSkip(vlf);
    final e = (code == kPixelData)
        ? makePixelData(code, rb.subbytes(eStart, rb.index), vrIndex)
        : makeFromBytes(code, rb.subbytes(eStart, rb.index), vrIndex);
//    logEndRead(eStart, e, 'readEvrLong');
    return e;
  }

  @override
  Element makePixelData(int code, Bytes bd, int vrIndex,
      [TransferSyntax ts, VFFragments fragments]) {
    ts ??= defaultTS;
    return EvrElement.makePixelData(code, bd, vrIndex, ts, fragments);
  }

  TransferSyntax get defaultTS => _defaultTS ??= rds.transferSyntax;
  TransferSyntax _defaultTS;

  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  ///
  //  If the VR is UN then it may be a Sequence.  If it is a Sequence, it will
  //  start with either a kItem delimiter or if it is an empty undefined length
  //  Sequence it will start with a kSequenceDelimiter.
  Element readMaybeUndefined(int code, int vrIndex, int eStart) {
    rb.rSkip(2);
    final vlf = rb.readUint32();
//    logStartRead(code, vrIndex, eStart, vlf, 'readEvrMaybeUndefined');

    // If VR is UN then this might be a Sequence
    if ((vrIndex == kUNIndex) && doConvertUNSequences && isUNSequence(vlf)) {
      log.warn('Converting UN to SQ');
      final sq = _readUSQ(code, vrIndex, eStart, vlf);
//      logEndRead(eStart, sq, 'readEvrMaybeUndefined');
      return sq;
    }

    if (vlf != kUndefinedLength) return _makeLong(code, vrIndex, eStart, vlf);

    final fragments = readUndefinedLength(code, eStart, vrIndex, vlf);
    final bytes = rb.subbytes(eStart, rb.index);
    final e = (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex, defaultTS, fragments)
        : makeFromBytes(code, bytes, vrIndex);
//    logEndRead(eStart, e, 'readEvrMaybeUndefined');
    return e;
  }

  /// Read an EVR Sequence.
  @override
  SQ readSequence(int code, int vrIndex, int eStart) {
    assert(vrIndex == kSQIndex);
    rb.rSkip(2);
    final vlf = rb.readUint32();
//    logStartSQRead(code, vrIndex, eStart, vlf, 'readEvrSequence');
    return (vlf == kUndefinedLength)
        ? _readUSQ(code, vrIndex, eStart, vlf)
        : _readDSQ(code, vrIndex, eStart, vlf);
  }

  @override
  SQ makeSequence(int code, Dataset cds, List<Item> items, [Bytes bd]) =>
      EvrElement.makeSequence(code, cds, items, bd);

  /// Reads a [kUndefinedLength] Sequence.
  SQ _readUSQ(int code, int vrIndex, int eStart, int vlf) {
    assert(vrIndex == kSQIndex);
    assert(vlf == kUndefinedLength);
    final items = <Item>[];
    while (!isSequenceDelimiter()) {
      final item = readItem();
      items.add(item);
    }
    final e = makeSequence(code, cds, items, rb.subbytes(eStart, rb.index));
//    logEndSQRead(eStart, e, 'readEvrSequenceULength');
    return e;
  }

  /// Reads a defined [vfl].
  SQ _readDSQ(int code, int vrIndex, int eStart, int vfl) {
    assert(vrIndex == kSQIndex);
    assert(vfl != kUndefinedLength);
    final items = <Item>[];
    final eEnd = rb.index + vfl;

    while (rb.index < eEnd) {
      final item = readItem();
      items.add(item);
    }
    final end = rb.index;
    assert(eEnd == end, '$eEnd == $end');
    final e = makeSequence(code, cds, items, rb.subbytes(eStart, end));
//    logEndSQRead(eStart, e, 'readEvrSequenceDLength');
    return e;
  }

/*
  SQ _readSequenceDLength(int code, int vrIndex, int eStart, int vlf) {
    final items = readDSQ(code, vrIndex, eStart, vlf);
    final eb = rb.makeEvrLongEBytes(eStart);
    final e = makeSequence(code, eb, cds, items);
//    logEndSQRead(eStart, e, 'readEvrSequenceDLength');
    return e;
  }

  SQ _readSequenceULength(int code, int vrIndex, int eStart, int vlf) {
    final items = readUSQ(code, vrIndex, eStart, vlf);
    final eb = rb.makeEvrULengthEBytes(eStart);
    final e = makeSequence(code, eb, cds, items);
//    logEndSQRead(eStart, e, 'readEvrSequenceULength');
    return e;
  }
*/

  /// Reads File Meta Information (FMI) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  int _readFmi() {
    assert(rb.index == 0, 'Non-Zero Read Buffer Index');
    if (!_readPrefix(rb)) {
      rb.rIndex_ = 0;
      return -1;
    }
    assert(rb.index == 132, 'Non-Prefix start index: ${rb.index}');
    while (rb.isReadable) {
      final code = rb.peekCode();
      if (code >= 0x00030000) break;
      final e = readElement();
      rds.fmi[e.code] = e;
    }

    if (!rb.rHasRemaining(dParams.shortFileThreshold - rb.index)) {
      throw new EndOfDataError(
          '_readFmi', 'index: ${rb.index} bdLength: ${rb.lengthInBytes}');
    }

    final ts = rds.transferSyntax;
    log.info1('TS: $ts');
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
    rb.rSkip(128);
    final prefix = rb.readUint32();
    if (prefix == kDcmPrefix) return true;
    log.warn('No DICOM Prefix present');
    return false;
  }

  // *** This is an older/slower version, but keep for debugging.
  /// Read as ASCII String
  static bool isAsciiPrefixPresent(ReadBuffer rb) {
    final chars = rb.readUint8View(4);
    final prefix = ascii.decode(chars);
    if (prefix == 'DICM') return true;
    log.warn('No DICOM Prefix present');
    return false;
  }

  // **** Static Interface if implemented by subclasses.
  // static RootDataset readInstance(Bytes bd, RootDataset rds);

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
