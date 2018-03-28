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

bool doConvertUNSequences = false;

abstract class EvrSubReader extends SubReader {
  /// The [Bytes] being read by _this_.
  @override
  final Bytes bytes;

  EvrSubReader(this.bytes, DecodingParameters dParams, Dataset cds)
      : super(new ReadBuffer(bytes), dParams, cds);

  @override
  bool get isEvr => true;

  bool _isEvrShortVR(int vrIndex) =>
      vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element _readElement() {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final vrCode = rb.readUint16();
    final vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);
    final e = (_isEvrShortVR(vrIndex))
        ? _readShort(code, eStart, vrIndex)
        : _readLong(code, eStart, vrIndex);
    _count++;
    if (doLogging) print(_endMsg(e));
    return e;
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit Value Field Length field.
  /// These Elements can not have an kUndefinedLength value.
  Element _readShort(int code, int eStart, int vrIndex) {
    final vlf = rb.readUint16();
    assert(!vlf.isOdd, 'Odd vlf: $vlf');
    if (vlf.isOdd) log.error('Odd vlf: $vlf');
    if (doLogging) print(_startMsg(code, eStart, vrIndex, vlf));
    rb.rSkip(vlf);
    return makeFromBytes(code, rb.subbytes(eStart, rb.index), vrIndex, 8);
  }

  Element _readLong(int code, int eStart, int vrIndex) {
    rb.rSkip(2);
    final vlf = rb.readUint32();
    assert(vlf.isEven || vlf == kUndefinedLength, 'Odd vlf: $vlf');
    if (vlf.isOdd) log.error('Odd vlf: $vlf');
    if (doLogging) print(_startMsg(code, eStart, vrIndex, vlf));
    return __readLong(code, eStart, vrIndex, vlf, 12);
  }

  int _lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vrIndex = vrIndexFromCode(vrCode);
    if (vrIndex == null) {
      // TODO: this should throw
      _nullVRIndex(code, eStart, vrCode);
    } else if (_isSpecialVR(vrIndex)) {
      log.info('-- Changing (${hex32(code)}) with Special VR '
          '${vrIdFromIndex(vrIndex)}) to VR.kUN');
      return VR.kUN.index;
    } else if (Tag.isPCCode(code) &&
        (vrIndex != kLOIndex && vrIndex != kUNIndex)) {
      _invalidPrivateCreator(code, vrIndex);
    }
    return vrIndex;
  }

  void _nullVRIndex(int code, int eStart, int vrCode) {
    log.warn('Null VR: vrCode(${hex16(vrCode)}, $vrCode) '
        '${dcm(code)} start: $eStart');
  }

  void _invalidPrivateCreator(int code, int vrIndex) {
    assert(Tag.isPCCode(code) && (vrIndex != kLOIndex && vrIndex != kUNIndex));
    log.warn('** Invalid Private Creator (${hex32(code)}) '
        '${vrIdFromIndex(vrIndex)}($vrIndex) should be VR.kLO');
  }

  /// Reads File Meta Information (FMI) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  int readFmi() {
    if (rb.rIndex != 0) throw new InvalidReadBufferIndex(rb);
    assert(rb.index == 0, 'Non-Zero Read Buffer Index');
    if (!_readPrefix(rb)) {
      rb.rIndex_ = 0;
      return -1;
    }
    assert(rb.index == 132, 'Non-Prefix start index: ${rb.index}');
    while (rb.isReadable) {
      final code = rb.peekCode();
      if (code >= 0x00030000) break;
      final e = _readElement();
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
    final vlf = rb.readUint32();
    final tag = (doLookupVRIndex) ? _lookupTag(code, eStart) : null;
    final vrIndex = (tag == null) ? kUNIndex : tag.vrIndex;
    if (doLogging) print(_startMsg(code, eStart, vrIndex, vlf));
    final e = __readLong(code, eStart, vrIndex, vlf, 8);
    _count++;
    if (doLogging) print(_endMsg(e));
    return e;
  }

  Tag _lookupTag(int code, int eStart, [int vrIndex, Object token]) {
    if (Tag.isPDCode(code)) {
      // **** temporary
      return Tag.lookupByCode(code);
    } else if (Tag.isPCCode(code)) {
      // **** temporary
      return Tag.lookupByCode(code);
    } else {
      assert(Tag.isPrivateCode(code));
      return PTag.lookupByCode(code);
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

  /// The current [Element] [Map].
  Iterable<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  Iterable<Element> get duplicates => cds.history.duplicates;

  bool get isReadable => rb.isReadable;

  Uint8List get rootBytes => rb.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  TransferSyntax get defaultTS => _defaultTS ??= rds.transferSyntax;
  TransferSyntax _defaultTS;

  /// The number of Elements that have been read.
  int _count = 0;
  int get count => _count;

  /// Returns a new [Item], with not [Element].
  Item _makeEmptyItem(Dataset parent, [SQ sequence]) =>
      makeItem(parent, sequence, <int, Element>{});

  final String kItem32BitLEAsString = hex32(kItem32BitLE);

  /// Reads a [RootDataset] from _this_. The FMI, if any, MUST already be read.
  RootDataset readRootDataset([int fmiEnd]) {
    fmiEnd ??= rb.rIndex;
    cds = rds;
    final rdsStart = rb.rIndex;
    readDatasetDefinedLength(rds, rdsStart, rb.rRemaining);
    final rdsLength = rb.rIndex - rdsStart;
    final rbd = rb.asBytes(rdsStart, rdsLength);
    rds.dsBytes = new RDSBytes(rbd, fmiEnd);
    return rds;
  }

  /// Returns an [Item].
  // rIndex is @ delimiterFvr
  Item readItem([SQ sq]) {
    assert(rb.rHasRemaining(8));
    final iStart = rb.rIndex;

    // read 32-bit kItem code and Item length field
    final delimiter = rb.getUint32();
    if (delimiter != kItem32BitLE) throw 'Missing Item Delimiter';
    rb.rSkip(4);
    final vfLengthField = rb.readUint32();
    final item = _makeEmptyItem(cds);
    final parentDS = cds;
    cds = item;

    (vfLengthField == kUndefinedLength)
        ? _readDatasetUndefinedLength(item, rb.index)
        : _readDatasetDefinedLength(item, rb.index, vfLengthField);

    final bd = rb.subbytes(iStart, rb.rIndex);
    final dsBytes = new IDSBytes(bd);
    item.dsBytes = dsBytes;
    cds = parentDS;
    return item;
  }

  // **** This is one of the only two places Elements are added to the dataset.
  // **** This is the other of the only two places Elements are added to the dataset.

  void readDatasetDefinedLength(Dataset ds, int dsStart, int vfLength) =>
      _readDatasetDefinedLength(ds, dsStart, vfLength);

  // **** This is one of the only two places Elements are added to the dataset.
  void _readDatasetDefinedLength(Dataset ds, int dsStart, int vfLength) {
    assert(vfLength != kUndefinedLength);
    assert(dsStart == rb.rIndex);
    final dsEnd = dsStart + vfLength;
    while (rb.rIndex < dsEnd) {
      // Elements are always read into the current dataset.
      final e = _readElement();
//      print('@${rb.index}: $e');
      final ok = ds.tryAdd(e);
      if (!ok) log.warn('*** duplicate: $e');
    }
  }

  void readDatasetUndefinedLength(Dataset ds, int dsStart) =>
      _readDatasetUndefinedLength(ds, dsStart);

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

  /// Read a long Element (i.e. with a32-bit vfLengthField),
  /// which might have a value of [kUndefinedLength].
  ///
  /// Returns one of SQ, OB, OW, or UN, which are the only [Element]s
  /// that may have a Value Length Field of [kUndefinedLength].
  ///
  //  If the VR is UN then it may be a Sequence.  If it is a Sequence, it will
  //  start with either a kItem delimiter or if it is an empty undefined length
  //  Sequence it will start with a kSequenceDelimiter.
  Element __readLong(int code, int eStart, int vrIndex, int vlf, int vfOffset) {
    if (_isSequenceVR(vrIndex) || (vrIndex == kUNIndex && _isUNSequence(vlf)))
      return _readSequence(code, eStart, vrIndex, 8, vlf);
    if (vlf == kUndefinedLength)
      return _readLongUndefinedLength(code, eStart, vrIndex, 12, vlf);
    // Return a defined length Element with a long Value Field
    rb.rSkip(vlf);
    final bytes = rb.subbytes(eStart, rb.index);
    return (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex, vfOffset)
        : makeFromBytes(code, bytes, vrIndex, vfOffset);
  }

  // If VR is UN then this might be a Sequence
  bool _isUNSequence(int delimiter) =>
      (delimiter == kSequenceDelimitationItem32BitLE) || (delimiter == kItem);

  /// Read a long Element (i.e. 32-bit vfLengthField), which is not SQ,
  /// that might have a value of kUndefinedValue. [vrIndex] must be one of
  /// OB, OW, and UN.
  ///
  /// There are four [Element]s that might have an Undefined Length value
  /// (0xFFFFFFFF), [SQ], [OB], [OW], [UN].
  Element _readLongUndefinedLength(
      int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(vlf == kUndefinedLength && _isMaybeUndefinedLengthVR(vrIndex));
    assert(vrIndex != kSQIndex);
    VFFragments fragments;
    if (code == kPixelData) {
      _readEncapsulatedPixelData(code, eStart, vrIndex, vlf);
    } else {
      _findEndOfULengthVF();
    }
    final bytes = rb.subbytes(eStart, rb.index);
    return (code == kPixelData)
        ? makePixelData(
            code, bytes, vrIndex, vfOffset, vlf, defaultTS, fragments)
        : makeFromBytes(code, bytes, vrIndex, vfOffset);
  }

  /// Called if the [vrIndex] is [kSQIndex], or if [vrIndex] is [kUNIndex]
  /// and then it may be a Sequence.  If it is a Sequence, it will start
  /// with either a kItem delimiter or if it is an empty undefined length
  /// Sequence it will start with a kSequenceDelimiter.
  ///
  /// If the [vlf] is the Undefined, then it searches for the matching
  /// kSequenceDelimitationItem32Bit to determine the length. Returns an
  /// [SQ] [Element].
  SQ _readSequence(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(vrIndex == kSQIndex);
    return (vlf == kUndefinedLength)
        ? _readUSQ(code, eStart, vrIndex, vfOffset, vlf)
        : _readDSQ(code, eStart, vrIndex, vfOffset, vlf);
  }

  bool _isSequenceVR(int vrIndex) => vrIndex == 0;

  /// Reads a [kUndefinedLength] Sequence.
  SQ _readUSQ(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(vrIndex == kSQIndex && vlf == kUndefinedLength);
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

  /// Reads a defined [vfl].
  SQ _readDSQ(int code, int eStart, int vrIndex, int vfOffset, int vfl) {
    assert(vrIndex == kSQIndex && vfl != kUndefinedLength);
    final items = <Item>[];
    final eEnd = rb.index + vfl;

    while (rb.index < eEnd) {
      final item = readItem();
      items.add(item);
    }
    final end = rb.index;
    assert(eEnd == end, '$eEnd == $end');
    return makeSequence(
        code, cds, items, vfOffset, vfl, rb.subbytes(eStart, end));
  }

  /// Returns [VFFragments] for this [kPixelData] Element.
  /// There are only three VRs that use this: OB, OW, UN.
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

  String _startMsg(int code, int eStart, int vrIndex, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    return '>@R${eStart - 6} ${dcm(code)} $vrId($vrIndex) $len';
  }

  String _endMsg(Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    return '<@R${rb.index} $eNumber: $e';
  }

/*
  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  ///
  //  If the VR is UN then it may be a Sequence.  If it is a Sequence, it will
  //  start with either a kItem delimiter or if it is an empty undefined length
  //  Sequence it will start with a kSequenceDelimiter.
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
