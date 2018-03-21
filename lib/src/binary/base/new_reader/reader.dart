// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/utilities/element_offsets.dart';

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

typedef Element LongReader(int code, int eStart, int vrIndex);

bool doConvertUNSequences = false;

abstract class EvrReader extends Reader {
  @override
  Dataset cds;

  EvrReader(this.cds);

  bool _isEvrShortVR(int vrIndex) =>
      vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

  bool _isEvrLongVR(int vrIndex) =>
      vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

  @override
  int _readLongVFLengthField() {
    rb.rSkip(2);
    return rb.readUint32();
  }

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element _readElement() => _startReadElement(_readLong);

  @override
  Element _startReadElement(LongReader readLong) {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final vrCode = rb.readUint16();
    final vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);
//    final tag = _lookupTag(code, vrIndex, e)
    return (_isEvrShortVR(vrIndex))
        ? _readShort(code, vrIndex, eStart)
        : readLong(code, vrIndex, eStart);
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit Value Field Length field.
  /// These Elements can not have an kUndefinedLength value.
  Element _readShort(int code, int vrIndex, int eStart) {
    final vlf = rb.readUint16();
    if (vlf.isOdd) log.error('Odd vlf: $vlf');
    rb.rSkip(vlf);
    return makeFromBytes(code, rb.subbytes(eStart, rb.index), vrIndex);
  }

  @override
  Element _readLong(int code, int eStart, int vrIndex) {
    Element e;
    if (_isEvrLongVR(vrIndex)) {
      e = _readLongDefinedLength(code, eStart, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      e = _readSequence(code, eStart, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      e = _readMaybeUndefined(code, eStart, vrIndex);
    } else {
      return invalidVRIndex(vrIndex, null, null);
    }
    return e;
  }

  @override
  Element readShortElement(int code, int eStart, int vrIndex) =>
      _readShort(code, eStart, vrIndex);

  int readFmi(int eStart) {
    if (rb.rIndex != 0) throw new InvalidReadBufferIndex(rb);
    return _readFmi();
  }
}

abstract class IvrReader extends Reader {
  @override
  Dataset cds;

  IvrReader(this.cds);

  @override
  int _readLongVFLengthField() => rb.readUint32();

  @override
  Element _readElement() => _startReadElement(_readLong);

  @override
  Element _startReadElement(LongReader readLong) {
    final eStart = rb.rIndex;
    final code = rb.readCode();
    final tag = checkCode(code, eStart);
    final vrIndex = _lookupIvrVRIndex(code, eStart, tag);
    return _readLong(code, eStart, vrIndex);
    //  return _lookupTag(code, vrIndex, e);
  }

  @override
  Element _readLong(int code, int eStart, int vrIndex) {
    if (_isIvrDefinedLengthVR(vrIndex))
      return _readLongDefinedLength(code, eStart, vrIndex);
    if (_isSequenceVR(vrIndex)) return _readSequence(code, eStart, vrIndex);
    if (_isMaybeUndefinedLengthVR(vrIndex))
      return _readMaybeUndefined(code, eStart, vrIndex);
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
      log.warn('-- Changing Special VR ${vrIdFromIndex(vrIndex)}) to VR.kUN');
      vrIndex = VR.kUN.index;
    }
    return vrIndex;
  }

  bool _isIvrDefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

  int readFmi(int eStart) => unsupportedError();
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
abstract class Reader {
  // **** Interface ****

  /// The [ReadBuffer] being read.
  ReadBuffer get rb;
  DecodingParameters get dParams;
  Element _readElement();
  int _readLongVFLengthField();

  /// The [RootDataset].
  RootDataset get rds;

  /// The current Dataset.
  Dataset get cds;
  set cds(Dataset ds);

  Element _readLong(int code, int eStart, int vrIndex);

  // **** Interface for Implementers

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
  Element makeFromBytes(int code, Bytes bytes, int vrIndex);

  /// Returns a new [Element].
  // Note: Typically this may or may not be implemented.
  Element makeFromValues<V>(int code, List<V> values, int vrIndex,
          [Bytes bytes]) =>
      unsupportedError();

  /// Returns a new Pixel Data [Element].
  Element makePixelData(int code, Bytes bytes, int vrIndex,
      [TransferSyntax ts, VFFragments fragments]);

  /// Creates a new Sequence ([SQ]) [Element].
  SQ makeSequence(int code, Dataset cds, List<Item> items, [Bytes bytes]);

  // **** End of Interface

  /// Returns a new [Item], with not [Element].
  Item makeEmptyItem(Dataset parent, [SQ sequence]) =>
      makeItem(parent, sequence, <int, Element>{});

  /// The current [Element] [Map].
  Iterable<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  Iterable<Element> get duplicates => cds.history.duplicates;

  bool get isReadable => rb.isReadable;

  Uint8List get rootBytes => rb.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  ElementOffsets get offsets => null;

  bool hasRemaining(int n) => rb.rHasRemaining(n);

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem32Bit] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  final String kItemAsString = hex32(kItem32BitLE);

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
    final item = makeEmptyItem(cds);
    final parentDS = cds;
    cds = item;

    (vfLengthField == kUndefinedLength)
        ? readDatasetUndefinedLength(item)
        : readDatasetDefinedLength(item, rb.rIndex, vfLengthField);

    final bd = rb.subbytes(iStart, rb.rIndex);
    final dsBytes = new IDSBytes(bd);
    item.dsBytes = dsBytes;
    cds = parentDS;
    return item;
  }

  // **** This is one of the only two places Elements are added to the dataset.
  // **** This is the other of the only two places Elements are added to the dataset.

  // **** This is one of the only two places Elements are added to the dataset.
  void readDatasetDefinedLength(Dataset ds, int dsStart, int vfLength) {
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

  void readDatasetUndefinedLength(Dataset ds) {
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

  // If VR is UN then this might be a Sequence
  bool isUNSequence(int delimiter) =>
      (delimiter == kSequenceDelimitationItem32BitLE) || (delimiter == kItem);

  // When this method is called, the [rIndex] should be at the beginning
  // of the Value Field. When it returns the [rIndex] be at the end of
  // the delimiter.
  // Note: Since for binary DICOM the Value Field is 16-bit aligned,
  // it must be checked 16 bits at a time.
  //
  /// Reads until a [kSequenceDelimitationItem32BitLE] is found, and
  /// returns the [rb].rIndex at the end of the Value Field.
  int _findEndOfULengthVF() {
    while (rb.isReadable) {
      if (uint16 != kDelimiterFirst16Bits) continue;
      if (uint16 != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    final length = rb.readUint32();
    if (length != 0) log.warn('Encountered non-zero delimiter length($length)');
    final endOfVF = rb.rIndex - 8;
    return endOfVF;
  }

  /// If the sequence delimiter is found at the current _read index_, reads the
  /// _delimiter_, reads and checks the _delimiter length_ field, and returns _true_.
  bool isSequenceDelimiter() =>
      _checkForDelimiter(kSequenceDelimitationItem32BitLE);

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

  void _readAndCheckDelimiterLength() {
    final length = rb.readUint32();
    if (length != 0) log.warn('Encountered non-zero delimiter length($length)');
  }

  // Finish reading an Undefined Length Element. Return [VFFragments] or null.
  VFFragments readUndefinedLength(int code, int eStart, int vrIndex, int vlf) {
    assert(vlf == kUndefinedLength);
    if (code == kPixelData) {
      return _readEncapsulatedPixelData(code, eStart, vrIndex, vlf);
    } else {
      _findEndOfULengthVF();
      return null;
    }
  }

  /// Returns [VFFragments] for this [kPixelData] Element.
  /// There are only three VRs that use this: OB, OW, UN.
  ///
  // _rIndex is Just after vfLengthField
  VFFragments _readEncapsulatedPixelData(
      int code, int eStart, int vrIndex, int vlf) {
    assert(vlf == kUndefinedLength);
    assert(_isMaybeUndefinedLengthVR(vrIndex));

    final delimiter = rb.getUint32();
    if (delimiter == kItem32BitLE) {
      return _readPixelDataFragments(code, eStart, vrIndex, vlf);
    } else if (delimiter == kSequenceDelimitationItem32BitLE) {
      // An Empty Pixel Data Element
      _readAndCheckDelimiterLength();
      return null;
    } else {
      throw 'Non-Delimiter ${dcm(delimiter)}, $delimiter found';
    }
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

  void _checkDelimiterLength(int delimiter) {
    final vfLengthField = rb.readUint32();
    if (vfLengthField != 0)
      log.warn('Delimiter has non-zero '
          'value: $delimiter/0x${hex32(delimiter)}');
  }

  Tag checkCode(int code, int eStart) {
    final tag = Tag.lookupByCode(code);
    if (tag == null) log.warn('Tag is Null: ${dcm(code)} start: $eStart');
    return tag;
  }

  bool isValidVR(int code, int vrIndex, Tag tag) =>
      _isValidVR(code, vrIndex, tag);

  bool _isValidVR(int code, int vrIndex, Tag tag) {
    if (vrIndex == kUNIndex) return true;
    if (tag.hasNormalVR && vrIndex == tag.vrIndex) return true;
    if (tag.hasSpecialVR && isNormalVRIndex(vrIndex)) return true;
    if (tag is PDTagUnknown) return true;
    return false;
  }

  bool isNotValidVR(int code, int vrIndex, Tag tag) =>
      !_isValidVR(code, vrIndex, tag);

  int correctVR(int code, int vrIndex, Tag tag) {
    if (vrIndex == kUNIndex) {
      if (tag.vrIndex == kUNIndex) return vrIndex;
      return (tag.hasNormalVR) ? tag.vrIndex : vrIndex;
    }
    return vrIndex;
  }

  /// Returns true if there are only trailing zeros at the end of the
  /// Object being parsed.
  Null zeroEncountered(int code) =>
      throw new EndOfDataError('Zero encountered');

  String failedTSErrorMsg(String path, Error x) => '''
Invalid Transfer Syntax: "$path"\nException: $x\n 
    File length: ${rb.lengthInBytes}\nreadFMI catch: $x
''';

  String failedFMIErrorMsg(String path, Object x) => '''
Failed to read FMI: "$path"\nException: $x\n'
	  File length: ${rb.lengthInBytes}\nreadFMI catch: $x');
''';

  @override
  String toString() => '$runtimeType: rds: $rds, cds: $cds';

  Null shortFileError(String path) {
    final s = 'Short file error: length(${rb.lengthInBytes}) $path';
    log.warn('$s');
    if (throwOnError)
      throw new ShortFileError('Length($rb.lengthInBytes) $path');
    return null;
  }

  bool _isSequenceVR(int vrIndex) => vrIndex == 0;

  bool _isSpecialVR(int vrIndex) =>
      vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

  bool _isMaybeUndefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRMaybeUndefinedIndexMin &&
      vrIndex <= kVRMaybeUndefinedIndexMax;

  /// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// which cannot have the value kUndefinedValue.
  ///
  /// Reads one of OD, OF, OL, UC, UR, or UT.
  Element _readLongDefinedLength(int code, int vrIndex, int eStart) {
    final vlf = _readLongVFLengthField();
    if (vlf.isOdd) log.error('Odd vlf: $vlf');
    return _makeLong(code, vrIndex, eStart, vlf);
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

  /// Returns an EVR Element with a long Value Field
  Element _makeLong(int code, int vrIndex, int eStart, int vlf) {
    assert(vlf != kUndefinedLength);
    rb.rSkip(vlf);
    final bytes = rb.subbytes(eStart, rb.index);
    return (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex)
        : makeFromBytes(code, bytes, vrIndex);
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
  Element _readMaybeUndefined(int code, int vrIndex, int eStart) {
    final vlf = _readLongVFLengthField();
    // If VR is UN then this might be a Sequence
    if ((vrIndex == kUNIndex) && doConvertUNSequences && isUNSequence(vlf)) {
      log.warn('Converting UN to SQ');
      final sq = _readUSQ(code, vrIndex, eStart, vlf);
      return sq;
    }

    if (vlf != kUndefinedLength) return _makeLong(code, vrIndex, eStart, vlf);
    final fragments = readUndefinedLength(code, eStart, vrIndex, vlf);
    final bytes = rb.subbytes(eStart, rb.index);
    return (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex, defaultTS, fragments)
        : makeFromBytes(code, bytes, vrIndex);
  }

  SQ _readSequence(int code, int vrIndex, int eStart) {
    assert(vrIndex == kSQIndex);
    final vlf = _readLongVFLengthField();
    return (vlf == kUndefinedLength)
        ? _readUSQ(code, vrIndex, eStart, vlf)
        : _readDSQ(code, vrIndex, eStart, vlf);
  }

  /// Reads a [kUndefinedLength] Sequence.
  SQ _readUSQ(int code, int vrIndex, int eStart, int vlf) {
    assert(vrIndex == kSQIndex && vlf == kUndefinedLength);
    final items = <Item>[];
    while (!isSequenceDelimiter()) {
      final item = readItem();
      items.add(item);
    }
    return makeSequence(code, cds, items, rb.subbytes(eStart, rb.index));
  }

  /// Reads a defined [vfl].
  SQ _readDSQ(int code, int vrIndex, int eStart, int vfl) {
    assert(vrIndex == kSQIndex && vfl != kUndefinedLength);
    final items = <Item>[];
    final eEnd = rb.index + vfl;

    while (rb.index < eEnd) {
      final item = readItem();
      items.add(item);
    }
    final end = rb.index;
    assert(eEnd == end, '$eEnd == $end');
    return makeSequence(code, cds, items, rb.subbytes(eStart, end));
  }

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

  // *** This is an older/slower version, but keep for debugging.
  /// Read as ASCII String
  static bool isAsciiPrefixPresent(ReadBuffer rb) {
    final chars = rb.readUint8View(4);
    final prefix = ascii.decode(chars);
    if (prefix == 'DICM') return true;
    log.warn('No DICOM Prefix present');
    return false;
  }

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

  Element _startReadElement(LongReader readLong);
  // **** External Interface

  Element readElement() => startReadElement(readLongElement);

  // Defaults to unsupported for IVR
  Element readShortElement(int code, int eStart, int vrIndex) => unsupportedError();
  Element startReadElement(LongReader readLong) => _startReadElement(readLong);
  Element readLongElement(int code, int eStart, int vrIndex) =>
      _readLong(code, eStart, vrIndex);

  /// Read a Sequence.
  SQ readSequence(int code, int eStart, int vrIndex) =>
      _readSequence(code, vrIndex, eStart);
}

class InvalidReadBufferIndex extends Error {
  final ReadBuffer rb;
  final int index;

  InvalidReadBufferIndex(this.rb, [int index]) : index = index ?? rb.index;

  @override
  String toString() => 'InvalidReadBufferIndex($index): $rb';
}
