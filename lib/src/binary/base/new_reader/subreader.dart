// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/errors.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/parse_info.dart';

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

typedef Element LongElementReader(int code, int eStart, int vrIndex, int vlf);

abstract class EvrSubReader extends SubReader {
  /// The [Bytes] being read by _this_.
  @override
  final Bytes bytes;

  EvrSubReader(this.bytes, DecodingParameters dParams, Dataset cds)
      : super(new ReadBuffer(bytes), dParams, cds);

  /// Returns _true_ if reading an Explicit VR Little Endian file.
  @override
  bool get isEvr => true;

  /// Returns _true_ if the VR has a 16-bit Value Field Length field.
  bool _isEvrShortVR(int vrIndex) =>
      vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element _readElement() {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final vrCode = rb.readUint16();
    final vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);
    int vlf;
    if (_isEvrShortVR(vrIndex)) {
      vlf = rb.readUint16();
      return _readDefinedLength(code, eStart, vrIndex, 8, vlf);
    } else {
      rb.rSkip(2);
      vlf = rb.readUint32();
      return _readLong(code, eStart, vrIndex, 12, vlf);
    }
  }

/* Flush
  /// Read a Short EVR Element, i.e. one with a 16-bit Value Field Length field.
  ///
  /// Note: These Elements can not have an kUndefinedLength value.
  Element _readShort(int code, int eStart, int vrIndex) {
    final vlf = rb.readUint16();
    assert(rb.index.isEven && vlf.isEven, 'Odd vlf: $vlf');
    if (doLogging) _startElementMsg(code, eStart, vrIndex, vlf);
    rb.rSkip(vlf);
    final e = makeFromBytes(code, rb.subbytes(eStart, rb.index), vrIndex, 8);
    if (doLogging) _endElementMsg(e);
    return e;
  }

  /// Read a Long EVR Element (i.e. with a 32-bit vfLengthField),
  /// which might have a value of [kUndefinedLength].
  Element _readEvrLong(int code, int eStart, int vrIndex) {
    rb.rSkip(2);
    final vlf = rb.readUint32();
    return _readLong(code, eStart, vrIndex, 12, vlf);
  }
*/

  int _lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vrIndex = vrIndexFromCode(vrCode);
    if (vrIndex == null) {
      // TODO: this should throw
      _nullVRIndex(code, eStart, vrCode);
    } else if (_isSpecialVR(vrIndex)) {
      log.warn('-- Changing (${hex32(code)}) with Special VR '
          '${vrIdFromIndex(vrIndex)}) to VR.kUN');
      return VR.kUN.index;
    } else if (Tag.isPCCode(code) &&
        (vrIndex != kLOIndex && vrIndex != kUNIndex)) {
      _invalidPrivateCreator(code, vrIndex);
    }
    return vrIndex;
  }

  void _nullVRIndex(int code, int eStart, int vrCode) {
    log.warn('@$eStart ${dcm(code)} Null VR(${hex16(vrCode)}, $vrCode)');
  }

  void _invalidPrivateCreator(int code, int vrIndex) {
    assert(Tag.isPCCode(code) && (vrIndex != kLOIndex && vrIndex != kUNIndex));
    log.warn('** Invalid Private Creator (${hex32(code)}) '
        '${vrIdFromIndex(vrIndex)}($vrIndex) should be VR.kLO');
  }

  /// Reads File Meta Information (FMI) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  int readFmi() {
    if (doLogging) log.debug('Reading FMI:', 1);
    if (rb.rIndex != 0) throw new InvalidReadBufferIndex(rb);
    assert(rb.index == 0, 'Non-Zero Read Buffer Index');
    if (!_readPrefix(rb)) {
      rb.rIndex_ = 0;
      if (doLogging)  log.up;
      return -1;
    }
    assert(rb.index == 132, 'Non-Prefix start index: ${rb.index}');
    if (doLogging) log.down;
    while (rb.isReadable) {
      final code = rb.peekCode();
      if (code >= 0x00030000) break;
      final e = _readElement();
      rds.fmi[e.code] = e;
    }

    if (!rb.rHasRemaining(dParams.shortFileThreshold - rb.index)) {
      if (doLogging) log.up;
      throw new EndOfDataError(
          '_readFmi', 'index: ${rb.index} bdLength: ${rb.lengthInBytes}');
    }
    if (doLogging) log.up;

    final ts = rds.transferSyntax;
    if (doLogging) log.debug('TS: $ts');
    if (!system.isSupportedTransferSyntax(ts.asString)) {
      return invalidTransferSyntax(ts);
    }
    if (dParams.targetTS != null && ts != dParams.targetTS)
      return invalidTransferSyntax(ts, dParams.targetTS);

    if (doLogging)
      log
        ..debug('<R@${rb.index} FinishedReading FMI:', -1)
        ..up;
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
}

abstract class IvrSubReader extends SubReader {
  final bool doLookupVRIndex;
  IvrSubReader(ReadBuffer rb, DecodingParameters dParams, Dataset cds,
      this.doLookupVRIndex)
      : super(rb, dParams, cds);

  @override
  bool get isEvr => false;

  /// The [Bytes] being read by _this_.
  @override
  Bytes get bytes => rb.buffer;

  @override
  Element _readElement() {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final tag = (doLookupVRIndex) ? _lookupTag(code, eStart) : null;
    final vrIndex = (tag == null) ? kUNIndex : tag.vrIndex;
    final vlf = rb.readUint32();
    return _readLong(code, eStart, vrIndex, 8, vlf);
  }

/*  Element _readIvrLong(int code, int eStart, int vrIndex, int vfOffset) {
    final vlf = rb.readUint32();
    assert(vlf.isEven || vlf == kUndefinedLength, 'Odd vlf: $vlf');
    if (vlf.isOdd) log.error('Odd vlf: $vlf');
    final delimiter = rb.getUint32();

    Element e;
    if (vrIndex == kSQIndex ||
        delimiter == kItem32BitLE ||
        delimiter == kSequenceDelimitationItem32BitLE) {
      e = _readSequence(code, eStart, vrIndex, vfOffset, vlf);
    } else if (vlf == kUndefinedLength) {
      e = _readLongUndefinedLength(code, eStart, vrIndex, vfOffset, vlf);
    } else {
      e = _readLongDefinedLength(code, eStart, vrIndex, vfOffset, vlf);
    }
    return e;
  }
  */
  Tag _lookupTag(int code, int eStart, [int vrIndex, Object token]) {
    // Urgent Fix
    if (Tag.isPublicCode(code)) {
      return PTag.lookupByCode(code);
    } else if (Tag.isPDCode(code)) {
      // **** temporary
      return Tag.lookupByCode(code);
    } else if (Tag.isPCCode(code)) {
      return Tag.lookupByCode(code);
    } else {
      print('code: ${dcm(code)}');
      return Tag.lookupByCode(code);
    }
  }
}

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
abstract class SubReader {
  /// The [ReadBuffer] being read.
  final ReadBuffer rb;

  /// Decoding parameters
  final DecodingParameters dParams;

  /// The current Dataset.
  Dataset cds;

  SubReader(this.rb, this.dParams, this.cds);

  // **** Interface for Evr and Ivr ****
  bool get isEvr;
  Bytes get bytes;
  RootDataset get rds;
  bool get doLogging;

  /// Reads and returns the next [Element] in the [ReadBuffer].
  Element _readElement();

  /// Creates an RootDataset.
  // Note: Typically this is not implemented.
  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          Bytes bd, int fmiEnd) =>
      unimplementedError();

  /// Creates an Item.
  Item makeItem(Dataset parent,
      [SQ sequence, Map<int, Element> eMap, Bytes bd]);

  /// Creates an Element from [Bytes].
// TODO: maybe in future to lift the dependency on bytes
//  Element makeFromIndex(int code, int eStart, int eEnd, int vfl, int vrIndex);

  /// Creates an Element from [Bytes].
  Element makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset);

  /// Returns a new [Element].
  // Note: Typically this may or may not be implemented.
  Element makeFromValues<V>(int code, List<V> values, int vrIndex,
          [Bytes bytes]) =>
      unsupportedError();

  /// Returns a new Pixel Data [Element].
  Element makePixelData(int code, Bytes bytes, int vrIndex, int vfOffset,
      [int vfLengthField, TransferSyntax ts, VFFragments fragments]);

  /// Creates a new Sequence ([SQ]) [Element].
  SQ makeSequence(int code, Dataset cds, List<Item> items, int vfOffset,
      [int vfLengthField, Bytes bytes]);

  // **** Interface for Logging

  ElementOffsets get offsets => null;
  ParseInfo get pInfo => null;

  // **** End of Interface

  /// The number of Elements that have been read.
  int _count = 0;
  int get count => _count;

  /// The current [Element] [Map].
  Iterable<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  Iterable<Element> get duplicates => cds.history.duplicates;

  bool get isReadable => rb.isReadable;

  Uint8List get rootBytes => rb.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  TransferSyntax get defaultTS => _defaultTS ??= rds.transferSyntax;
  TransferSyntax _defaultTS;

  /// Returns a new [Item], with not [Element].
  Item _makeEmptyItem(Dataset parent, [SQ sequence]) =>
      makeItem(parent, sequence, <int, Element>{});

  final String kItem32BitLEAsString = hex32(kItem32BitLE);

  RootDataset readRootDataset(int fmiEnd) {
    final rdsStart = rb.index;
    final bufLength = rb.rRemaining;
    if (doLogging)
      _startDatasetMsg(rdsStart, 'subReadRootDataset', 0, bufLength, rds);
    _readDatasetDefinedLength(rds, rdsStart, bufLength);
    final rdsLength = rb.rIndex - fmiEnd;
    final rdsBytes = rb.asBytes(fmiEnd, rdsLength);
    final dsBytes = new RDSBytes(rdsBytes, fmiEnd);
    rds.dsBytes = dsBytes;
    if (doLogging) _endDatasetMsg(rb.index, 'subReadRootDataset', dsBytes, rds);
    return rds;
  }

  /// Reads and returns an [Item].
  Item readItem([SQ sq]) {
    assert(rb.rHasRemaining(8));
    final iStart = rb.rIndex;

    // read 32-bit kItem code and Item length field
    final delimiter = rb.readUint32();
    if (delimiter != kItem32BitLE) throw 'Missing Item Delimiter';
    final vlf = rb.readUint32();
    if (doLogging) _startDatasetMsg(iStart, 'readItem', delimiter, vlf, cds);
    final item = _makeEmptyItem(cds);
    final parentDS = cds;
    cds = item;

    (vlf == kUndefinedLength)
        ? _readDatasetUndefinedLength(item, rb.index)
        : _readDatasetDefinedLength(item, rb.index, vlf);

    final bd = rb.subbytes(iStart, rb.rIndex);
    final dsBytes = new IDSBytes(bd);
    item.dsBytes = dsBytes;
    cds = parentDS;
    if (doLogging) _endDatasetMsg(rb.index, 'readItem', dsBytes, item);
    return item;
  }

  // **** This is one of the only two places Elements are added to the dataset.
  // **** This is the other of the only two places Elements are added to the dataset.

  // **** This is one of the only two places Elements are added to the dataset.
  void _readDatasetDefinedLength(Dataset ds, int dsStart, int vfl) {
    assert(vfl != kUndefinedLength);
    assert(dsStart == rb.rIndex);
    final dsEnd = dsStart + vfl;
    while (rb.rIndex < dsEnd) {
      final e = _readElement();
      final ok = ds.tryAdd(e);
      if (!ok) log.warn('*** duplicate: $e');
    }
  }

  void _readDatasetUndefinedLength(Dataset ds, int dsStart) {
    while (!_isItemDelimiter()) {
      // Elements are always read into the current dataset.
      // **** This is the only place they are added to the dataset.
      final e = _readElement();
      final ok = ds.tryAdd(e);
      if (!ok) log.warn('*** duplicate: $e');
    }
  }

  /// If the item delimiter _kItemDelimitationItem32Bit_, reads and checks the
  /// _delimiter length_ field, and returns _true_.
  bool _isItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

  // When this method is called, the [rIndex] should be at the beginning
  // of the Value Field. When it returns the [rIndex] be at the end of
  // the delimiter.
  // Note: Since for binary DICOM the Value Field is 16-bit aligned,
  // it must be checked 16 bits at a time.
  //
  /// Reads until a [kSequenceDelimitationItem32BitLE] is found, and
  /// on return the [rb].rIndex at the end of the Value Field.
  void _findEndOfULengthVF() {
    while (rb.isReadable) {
      if (uint16 != kDelimiterFirst16Bits) continue;
      if (uint16 != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    final length = rb.readUint32();
    if (length != 0) log.warn('Encountered non-zero delimiter length($length)');
  }

  /// Returns true if the [target] delimiter is found. If the target
  /// delimiter is found the _read index_ is advanced to the end of the delimiter
  /// field (8 bytes); otherwise, readIndex does not change.
  bool _checkForDelimiter(int target) {
    final delimiter = rb.getUint32();
    if (target == delimiter) {
      rb.rSkip(4);
      final length = rb.readUint32();
      if (length != 0)
        log.warn('Encountered non-zero delimiter length($length)');
      return true;
    }
    return false;
  }

  /// Reads an returns an [Element] with a 32-bit Value Field. The
  /// [vfOffset] is 12 for EVR and 8 for IVR.
  Element _readLong(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(rb.index.isEven);
    if (vlf.isOdd && vlf != kUndefinedLength) log.error('Odd vlf: $vlf');
    final delimiter = rb.getUint32();

    if (vrIndex == kSQIndex ||
        (delimiter == kItem32BitLE && code != kPixelData) ||
        delimiter == kSequenceDelimitationItem32BitLE) {
      return _readSequence(code, eStart, vrIndex, 8, vlf);
    } else if (vlf == kUndefinedLength) {
      return _readLongUndefinedLength(code, eStart, vrIndex, vfOffset, vlf);
    } else {
      return _readDefinedLength(code, eStart, vrIndex, vfOffset, vlf);
    }
  }

  /// Called if the [vrIndex] is [kSQIndex]; or if the [vrIndex] is
  /// [kUNIndex] and the first 32 bits of the Value Field contain either
  /// [kItemDelimitationItem32BitLE] or [kSequenceDelimitationItem32BitLE].

  /// If it is a Sequence, it will start
  /// with either a [kItem32BitLE] delimiter or if it is an empty undefined length
  /// Sequence it will start with a kSequenceDelimiter.
  ///

  SQ _readSequence(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    if (vrIndex != kSQIndex) {
      if (vrIndex == kUNIndex) {
        log.warn('** Creating Sequence as UN(($vrIndex) ${dcm(code)}');
      } else {
        log.error('** Creating Sequence with vr($vrIndex) ${dcm(code)}');
      }
    }
    if (doLogging) _startSQMsg(code, eStart, vrIndex, vfOffset, vlf);
    final sq = (vlf == kUndefinedLength)
        ? _readUSQ(code, eStart, kSQIndex, vfOffset, vlf)
        : _readDSQ(code, eStart, kSQIndex, vfOffset, vlf);
    _count++;
    if (doLogging) _endSQMsg(sq);
    return sq;
  }

  /// Reads a Sequence with a Value Field Length [vlf]
  /// containing [kUndefinedLength].
  SQ _readUSQ(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(vlf == kUndefinedLength);
    final items = <Item>[];
    while (!_isSequenceDelimiter()) {
      final item = readItem();
      items.add(item);
    }
    return makeSequence(
        code, cds, items, vfOffset, vlf, rb.subbytes(eStart, rb.index));
  }

  /// If the sequence delimiter is found at the current _read index_, reads the
  /// _delimiter_, reads and checks the _delimiter length_ field, and returns _true_.
  bool _isSequenceDelimiter() =>
      _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  /// Reads a Sequence with a defined length Value Field Length [vfl].
  SQ _readDSQ(int code, int eStart, int vrIndex, int vfOffset, int vfl) {
    assert(vfl != kUndefinedLength);
    final items = <Item>[];
    final sqEnd = rb.index + vfl;
    while (rb.index < sqEnd) {
      final item = readItem();
      items.add(item);
    }
    assert(sqEnd == rb.index, '$sqEnd == ${rb.index}');
    final bytes = rb.subbytes(eStart, rb.index);
    return makeSequence(code, cds, items, vfOffset, vfl, bytes);
  }

  /// Reads an Element with a 32-bit Value Field Length Field [vlf]
  /// containing [kUndefinedLength] (which is not a Sequence ([SQ]}).
  ///
  /// Only three non-Sequence [Element]s can have Value Field Length
  /// Field [vlf] containing [kUndefinedLength] OB, OW, and UN.
  Element _readLongUndefinedLength(
      int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    if (doLogging) _startElementMsg(code, eStart, vrIndex, vlf);
    assert(vlf == kUndefinedLength && _isMaybeUndefinedLengthVR(vrIndex));
    assert(vrIndex != kSQIndex);
    VFFragments fragments;
    if (code == kPixelData) {
      fragments = _readEncapsulatedPixelData(code, eStart, vrIndex, vlf);
      assert(fragments != null);
    } else {
      _findEndOfULengthVF();
    }
    final bytes = rb.subbytes(eStart, rb.index);
    final e = (code == kPixelData)
        ? makePixelData(
            code, bytes, vrIndex, vfOffset, vlf, defaultTS, fragments)
        : makeFromBytes(code, bytes, vrIndex, vfOffset);
    _count++;
    if (doLogging) _endElementMsg(e);
    return e;
  }

  /// Return a defined length Element with a long Value Field
  Element _readDefinedLength(
      int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    if (doLogging) _startElementMsg(code, eStart, vrIndex, vlf);
    rb.rSkip(vlf);
    final bytes = rb.subbytes(eStart, rb.index);
    final e = (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex, vfOffset)
        : makeFromBytes(code, bytes, vrIndex, vfOffset);
    _count++;
    if (doLogging) _endElementMsg(e);
    return e;
  }

  /// Returns [VFFragments] for a [kPixelData] Element.
  /// There are only three valid VRs for this method: OB, OW, UN.
  VFFragments _readEncapsulatedPixelData(
      int code, int eStart, int vrIndex, int vlf) {
    assert(vlf == kUndefinedLength);
    assert(_isMaybeUndefinedLengthVR(vrIndex));
    final delimiter = rb.getUint32();
    if (delimiter == kItem32BitLE) {
      return _readPixelDataFragments(code, eStart, vrIndex, vlf);
    } else if (delimiter == kSequenceDelimitationItem32BitLE) {
      // An Empty Pixel Data Element
      _checkDelimiterLength(delimiter);
      return null;
    } else {
      throw 'Non-Delimiter ${dcm(delimiter)}, $delimiter found';
    }
  }

  void _checkDelimiterLength(int delimiter) {
    final vlf = rb.readUint32();
    if (vlf != 0) log.warn('Encountered non-zero delimiter length($vlf)');
  }

  /// Reads an encapsulated (compressed) [kPixelData] [Element].
  VFFragments _readPixelDataFragments(
      int code, int eStart, int vrIndex, int vlf) {
    assert(_isMaybeUndefinedLengthVR(vrIndex));
    _checkForOB(vrIndex, rds.transferSyntax);
    return _readFragments(code, vrIndex, vlf);
  }

  void _checkForOB(int vrIndex, TransferSyntax ts) {
    if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
      final vr = vrByIndex[vrIndex];
      log.warn('Invalid VR($vr) for Encapsulated TS: $ts');
    }
  }

  /// Read Pixel Data Fragments.
  /// They each start with an Item Delimiter followed by the 32-bit Item
  /// length field, which may not have a value of kUndefinedValue.
  VFFragments _readFragments(int code, int vrIndex, int vlf) {
    final fragments = <Uint8List>[];
    var delimiter = rb.readUint32();
    do {
      assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
      final vlf = rb.readUint32();
      assert(vlf != kUndefinedLength, 'Invalid length: ${dcm(vlf)}');

      final startOfVF = rb.rIndex;
      final endOfVF = rb.rSkip(vlf);
      fragments.add(rb.asUint8List(startOfVF, endOfVF - startOfVF));
      delimiter = rb.readUint32();
    } while (delimiter != kSequenceDelimitationItem32BitLE);

    _checkDelimiterLength(delimiter);
    final v = new VFFragments(fragments);
    return v;
  }

  bool _isSpecialVR(int vrIndex) =>
      vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

  bool _isMaybeUndefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRMaybeUndefinedIndexMin &&
      vrIndex <= kVRMaybeUndefinedIndexMax;

  void _startElementMsg(int code, int eStart, int vrIndex, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    log.debug('>@R$eStart ${dcm(code)} $vrId($vrIndex) $len');
  }

  void _endElementMsg(Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    log.debug('<@R${rb.index} $eNumber: $e');
  }

  void _startSQMsg(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    final msg = '>@R$eStart ${dcm(code)} $vrId($vrIndex) $len';
    log.debug(msg, 1);
  }

  void _endSQMsg(SQ e) {
    final eNumber = '$count'.padLeft(4, '0');
    final msg = '<@R${rb.index} $eNumber: $e';
    log.debug(msg, -1);
  }

  void _startDatasetMsg(
      int eStart, String name, int delimiter, int vlf, Dataset ds) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    log..debug('>@R$eStart $name ${dcm(delimiter)} $len $ds', 1);
  }

  void _endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds) {
//    final eNumber = '$count'.padLeft(4, '0');
    log
      ..debug('<@R$dsStart $name $dsBytes: $ds', -1)
      ..up;
  }

/*
  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  ///
  /// If the VR is UN then it may be a Sequence.  If it is a Sequence,
  /// it will start with either a [kItem32BitLE] delimiter,
  /// if it is an empty [kUndefinedLength] Sequence it will start
  /// with a [kSequenceDelimiter32BitLE].
  Element _readMaybeUndefined(
      int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    if ((vrIndex == kUNIndex) && _isUNSequence(vlf)) {
      log.warn('Converting UN to SQ');
      final sq = _readUSQ(code, eStart, vrIndex, vfOffset, vlf);
      return sq;
    }

    return (vlf != kUndefinedLength)
        ? _makeLong(code, eStart, vrIndex, vfOffset, vlf)
        : _readLongUndefinedLength(code, eStart, vrIndex, vfOffset, vlf);
  }
*/

/*
  // *** This is an older/slower version, but keep for debugging.
  /// Read as ASCII String
  static bool _isAsciiPrefixPresent(ReadBuffer rb) {
    final chars = rb.readUint8View(4);
    final prefix = ascii.decode(chars);
    if (prefix == 'DICM') return true;
    log.warn('No DICOM Prefix present');
    return false;
  }
*/
/*
  /// The current Group being read.
  int _group;


  Tag _lookupTag(int code, int vrIndex, Element e) {
    final group = code >> 16;
    if (group != _group) _group = -1;
    final tag = (group.isEven)
        ? PTag.lookupByCode(code, vrIndex)
        : _getPrivateTag(code, vrIndex, group, e);

    // Note: this is only relevant for EVR
    if (tag != null) {
      if (dParams.doCheckVR && _isNotValidVR(code, vrIndex, tag)) {
        final vr = vrIdFromIndex(vrIndex);
        log.error('**** VR $vr is not valid for $tag');
      }

      if (dParams.doCorrectVR) {
        //Urgent: implement replacing the VR, but must be after parsing
        final newVRIndex = _correctVR(code, vrIndex, tag);
        if (newVRIndex != vrIndex) {
          final newVR = tag.vr;
          log.info1('** Changing VR from $vrIndex to $newVR');
          //       vrIndex = newVR.index;
        }
      }
    }
    return tag;
  }

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
*/

  // **** External Interface

  Element readElement() => _readElement();

  /// Read a Sequence.
  SQ readSequence(int code, int eStart, int vrIndex, int vfOffset, int vlf) =>
      _readSequence(code, eStart, vrIndex, vfOffset, vlf);

  @override
  String toString() => '$runtimeType: rds: $rds, cds: $cds';
}

class InvalidReadBufferIndex extends Error {
  final ReadBuffer rb;
  final int index;

  InvalidReadBufferIndex(this.rb, [int index]) : index = index ?? rb.index;

  @override
  String toString() => 'InvalidReadBufferIndex($index): $rb';
}
