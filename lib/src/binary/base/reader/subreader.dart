//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/vf_fragments.dart';

import 'package:converter/src/binary/base/constants.dart';
import 'package:converter/src/errors.dart';
import 'package:converter/src/decoding_parameters.dart';
import 'package:converter/src/element_offsets.dart';
import 'package:converter/src/parse_info.dart';

// ignore_for_file: avoid_positional_boolean_parameters, only_throw_errors
// ignore_for_file: avoid_catches_without_on_clauses

// Reader axioms
// 1. eStart is always the first byte of the Element being read and eEnd
//    is always the end of the Element be
// 2. The read index (rIndex) should always be at the last place read,
//    and the end of the value field should be calculated by subtracting
//    the length of the delimiter (and delimiter length), which is 8 bytes.
//
// 2. For non-sequence Elements with undefined length (kUndefinedLength)
//    the Value Field Length (vfLength) of a non-Sequence Element.
//    The read index rIndex is left at the end of the Element Delimiter.
//
// 3. [_finishReadElement] is only called from [readByteElement] and
//    [readByteElement].

typedef LongElementReader = Element Function(
    int code, int eStart, int vrIndex, int vlf);

// TODO:
//   1. convert all if (doLogging) log.... to log....
//   2. make any error and warnings conditional

TransferSyntax _ts;

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
  /// The [DicomReadBuffer] being read.
  DicomReadBuffer _rb;

  /// Decoding parameters
  final DecodingParameters dParams;

  /// The current Dataset.
  Dataset cds;

  SubReader(this._rb, this.dParams, this.cds);

  DicomReadBuffer get rb => _rb;
  Endian get endian => _rb.buffer.endian;

  // **** Interface for Evr and Ivr ****
  bool get isEvr;
  RootDataset get rds;
  bool get doLogging;
  bool get doLookupVRIndex;

  Bytes get bytes => _rb.buffer;

  // ---- Interface ----

  TransferSyntax get ts => _ts;

  //Urgent Jim: cleanup interface
  /// Reads and returns the next [Element] in the [DicomReadBuffer].
  Element _readElement();

  /// Creates an Item.
  Item makeItem(Dataset parent,
      [SQ sequence, Map<int, Element> eMap, DicomBytes bd]);

  /// Creates an Element from [DicomBytes].
  Element makeFromBytes(DicomBytes bytes, Dataset ds, {bool isEvr});

  /// Creates an Element from [DicomBytes].
  Element makeMaybeUndefinedFromBytes(DicomBytes bytes, Dataset ds);

  /// Creates an Element from [DicomBytes].
  Element makePixelDataFromBytes(DicomBytes bytes,
      [TransferSyntax ts, VFFragmentList vf]);

  /// Create an SQ Element.
  Element makeSQFromBytes(Dataset parent,
      [Iterable<Item> items, DicomBytes bytes]);

  /// Returns a new [Element].
  // Note: Typically this may or may not be implemented.
  Element makeFromValues<V>(int code, int vrIndex, List<V> values) =>
      unsupportedError();

  /// Returns a new [Element] of type SQ, OB, OW, or UN.
  //  Designed to be overridden in TagElement.
  Element makeMaybeUndefinedFromValues(
          int code, Iterable values, int vrIndex) =>
      unsupportedError();

  /// Creates a new Sequence ([SQ]) [Element].
  //  Designed to be overridden in TagElement.
  SQ makeSequenceFromTag(Dataset parent, Tag tag, Iterable items,
          [DicomBytes bytes]) =>
      unsupportedError();

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

  bool get isReadable => _rb.isReadable;

  Bytes get rootBytes => _rb.view(_rb.offset, _rb.length);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  TransferSyntax get defaultTS => _defaultTS ??= rds.transferSyntax;
  TransferSyntax _defaultTS;

  /// Returns a new [Item], with not [Element].
  Item _makeEmptyItem(Dataset parent, [SQ sequence]) =>
      makeItem(parent, sequence, <int, Element>{});

  final String kItemAsString = hex32(kItem);

  RootDataset _readRootDataset(int fmiEnd) {
    final rdsStart = fmiEnd;
    final length = rb.remaining;
    if (doLogging) _startReadRootDataset(rdsStart, length);
    DSBytes dsBytes;
    try {
      _readDatasetDefinedLength(rds, rdsStart, length);
    } on EndOfDataError catch (e) {
      error('$e');
      //  if (throwOnError) rethrow;
    } on InvalidTransferSyntax catch (e) {
      error('$e');
      //  if (throwOnError) rethrow;
    } on DataAfterPixelDataError catch (e) {
      warn('$e');
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      error('$e');
      if (throwOnError) rethrow;
    } finally {
      final rdsLength = _rb.index - fmiEnd;
      final rdsBytes = _rb.view(0, rdsLength);
      dsBytes = RDSBytes(rdsBytes, fmiEnd);
      rds.dsBytes = dsBytes;
    }

    if (doLogging) _endReadRootDataset(rds, dsBytes);
    return rds;
  }

  /// Reads and returns an [Item].
  Item _readItem([SQ sq]) {
    assert(_rb.rHasRemaining(8));
    final iStart = _rb.index;

    // read 32-bit kItem code and Item length field
    final delimiter = _rb.readCode();
    if (delimiter != kItem) throw 'Missing Item Delimiter: ${hex32(delimiter)}';
    final vlf = _getVlf32();
    final item = _makeEmptyItem(cds);
    final parentDS = cds;
    cds = item;
    if (doLogging) _startDatasetMsg(iStart, 'readItem', delimiter, vlf, cds);

    if (vlf == kUndefinedLength) {
      _readDatasetUndefinedLength(item, _rb.index);
    } else {
      _readDatasetDefinedLength(item, _rb.index, vlf);
    }

    final bd = _rb.sublist(iStart, _rb.index);
    final dsBytes = IDSBytes(bd);
    item.dsBytes = dsBytes;
    cds = parentDS;
    if (doLogging) _endDatasetMsg(_rb.index, 'readItem', dsBytes, item);
    return item;
  }

  // **** This is one of the only two places Elements are added to the dataset.
  // **** This is the other of the only two places Elements are added to
  // **** the dataset.

  bool allowOddValueLengthField = true;

  // **** This is one of the only two places Elements are added to the dataset.
  void _readDatasetDefinedLength(Dataset ds, int dsStart, int vlf) {
    assert(vlf != kUndefinedLength && dsStart == _rb.index);
    assert(dsStart == _rb.index);
    ds.start = _rb.index;
    final dsEnd = dsStart + vlf;

    while (_rb.index < dsEnd) _readDataset(ds);

    if (vlf.isOdd) {
      final c = _rb.getUint8();
      final s = String.fromCharCode(c);
      error('Odd length Dataset: $vlf c= $c 0x${hex(c)} c: "$s"');
    }

    ds.end = _rb.index;
    if (dsEnd != ds.end)
      error('Item vlf($vlf) != Item length(${ds.end - ds.start})');
    assert(vlf == dsEnd - dsStart, '$vlf != ${dsEnd - dsStart}');
  }

  void _readDataset(Dataset ds) {
    final e = _readElement();
    final ok = ds.tryAdd(e);
    if (!ok) {
      warn('Duplicate: $e');
      cds.history.duplicates.add(e);
    }
  }

  void _readDatasetUndefinedLength(Dataset ds, int dsStart) {
    assert(dsStart == _rb.index);
    ds.start = _rb.index;
    while (!_isItemDelimiter()) _readDataset(ds);
    ds.end = _rb.index;
  }

  /// If the item delimiter _kItemDelimitationItem_, reads and checks the
  /// _delimiter length_ field, and returns _true_.
  bool _isItemDelimiter() => _checkForDelimiter(kItemDelimitationItem);

  // When this method is called, the [rIndex] should be at the beginning
  // of the Value Field. When it returns the [rIndex] be at the end of
  // the delimiter.
  // Note: Since for binary DICOM the Value Field is 16-bit aligned,
  // it must be checked 16 bits at a time.
  //
  /// Reads until a [kSequenceDelimitationItem] is found, and
  /// on return the [_rb].rIndex at the end of the Value Field.
  void _findEndOfULengthVF() {
    while (_rb.isReadable) {
      if (uint16 != kDelimiterFirst16Bits) continue;
      if (uint16 != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    final length = _rb.readUint32();
    if (length != 0) warn('Encountered non-zero delimiter length($length)');
  }

  /// Returns true if the [target] delimiter is found. If the target
  /// delimiter is found the _read index_ is advanced to the end of
  /// the delimiter field (8 bytes); otherwise, readIndex does not change.
  bool _checkForDelimiter(int target) {
    final delimiter = _rb.getCode(_rb.index);
    if (target == delimiter) {
      _rb.rSkip(4);
      final length = _rb.readUint32();
      if (length != 0) warn('Encountered non-zero delimiter length($length)');
      return true;
    }
    return false;
  }

  /// Reads and returns an [Element] with a 32-bit Value Field Length
  /// field. The [vfOffset] is 12 for EVR and 8 for IVR.
  Element _readLong(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(_rb.index.isEven);
    if (vlf.isOdd && vlf != kUndefinedLength) error('Odd vlf: $vlf');

    // Read but don't advance index
    final delimiter = _rb.getCode(eStart);

    if (vrIndex == kSQIndex) {
      return _readSequence(code, eStart, vrIndex, vfOffset, vlf);
    } else if (vrIndex == kUNIndex &&
        delimiter == kItem &&
        code != kPixelData) {
      final index = _rb.index;
      try {
        log.debug('** reading ${dcm(code)} vrIndex($vrIndex) vlf: $vlf');
        return _readSequence(code, eStart, vrIndex, vfOffset, vlf);
      } catch (e) {
        _rb.rIndex = index;
        log.up2;
        return (vlf == kUndefinedLength)
            ? _readUndefinedLength(code, eStart, vrIndex, vfOffset, vlf)
            : _readDefinedLength(code, eStart, vrIndex, vfOffset, vlf);
      }
    } else if (delimiter == kSequenceDelimitationItem &&
        vlf == kUndefinedLength) {
      // A Sequence that has a VR of UN.
      _rb.rSkip(4);
      final items = <Item>[_makeEmptyItem(cds)];
      final bytes = _rb.view(eStart, _rb.index - eStart);
      return makeSQFromBytes(cds, items, bytes);
    } else if (vlf == kUndefinedLength) {
      return _readUndefinedLength(code, eStart, vrIndex, vfOffset, vlf);
    } else {
      return _readDefinedLength(code, eStart, vrIndex, vfOffset, vlf);
    }
  }

  /// Read an Element with a long Value Field Length field, and
  /// return a defined length Element with a Value Field starting at
  /// [vfOffset].
  Element _readDefinedLength(
      int code, int start, int vrIndex, int vfOffset, int vlf) {
    if (doLogging) _startElementMsg(code, start, vrIndex, vlf);
    _rb.rSkip(vlf);
    final e = (code == kPixelData)
        ? _makePixelData(code, start, vrIndex, vfOffset, vlf)
        : _makeFromBytes(code, start, vrIndex, vfOffset);
    _count++;
    if (doLogging) _endElementMsg(e);
    return e;
  }

  Element _makeFromBytes(int code, int start, int vrIndex, int vfOffset) {
    final dBytes = _makeDicomBytes(start, vfOffset);
    return makeFromBytes(dBytes, cds, isEvr: isEvr);
  }

  DicomBytes _makeDicomBytes(int start, int vfOffset) {
    final end = _rb.index;
    return (!isEvr)
        ? IvrBytes.view(_rb.buffer, start, end)
        : (vfOffset == 8)
            ? EvrShortBytes.view(_rb.buffer, start, end, endian)
            : EvrLongBytes.view(_rb.buffer, start, end, endian);
  }

  /// Returns
  DicomBytes _makeLongDicomBytes(int start) => (!isEvr)
      ? IvrBytes.view(_rb.buffer, start, _rb.index)
      : EvrLongBytes.view(_rb.buffer, start, _rb.index, endian);

  bool _afterPixelData = false;

  /// Returns a new Pixel Data [Element].
  Element _makePixelData(
      int code, int start, int vrIndex, int vfOffset, int vfLengthField,
      [TransferSyntax ts, VFFragmentList fragments]) {
    _afterPixelData = true;
    final dBytes = _makeLongDicomBytes(start);
    return makePixelDataFromBytes(dBytes, ts, fragments);
  }

  /// Reads an Element with a 32-bit Value Field Length Field [vlf]
  /// containing [kUndefinedLength] (which is not a Sequence ([SQ]}).
  ///
  /// Only three non-Sequence [Element]s can have Value Field Length
  /// Field [vlf] containing [kUndefinedLength] OB, OW, and UN.
  ///
  /// _Note_: Undefined Length Elements always have a long (32-bit) VF.
  Element _readUndefinedLength(
      int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    if (doLogging) _startElementMsg(code, eStart, vrIndex, vlf);
    assert(vlf == kUndefinedLength &&
        _isMaybeUndefinedLengthVR(vrIndex) &&
        vrIndex != kSQIndex);

    VFFragmentList fragments;
    if (code == kPixelData) {
      fragments = _readEncapsulatedPixelData(code, eStart, vrIndex, vlf);
      assert(fragments != null);
    } else {
      _findEndOfULengthVF();
    }
    final e = (code == kPixelData)
        ? _makePixelData(
            code, eStart, vrIndex, vfOffset, vlf, defaultTS, fragments)
        : _makeFromBytes(code, eStart, vrIndex, vfOffset);
    _count++;
    if (doLogging) _endElementMsg(e);
    return e;
  }

  /// Called if the [vrIndex] is [kSQIndex]; or if the [vrIndex] is
  /// [kUNIndex] and the first 32 bits of the Value Field contain either
  /// [kItemDelimitationItem] or [kSequenceDelimitationItem].

  /// If it is a Sequence, it will start
  /// with either a [kItem] delimiter or if it is an empty undefined length
  /// Sequence it will start with a kSequenceDelimiter.
  ///

  SQ _readSequence(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    if (vrIndex != kSQIndex) {
      if (vrIndex == kUNIndex) {
        warn('Creating Sequence as UN(($vrIndex) ${dcm(code)}');
      } else {
        error('Creating Sequence with vr($vrIndex) ${dcm(code)}');
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
      final item = _readItem();
      items.add(item);
    }
    final dBytes = _makeLongDicomBytes(eStart);
    return makeSQFromBytes(cds, items, dBytes);
  }

  /// If the sequence delimiter is found at the current _read index_,
  /// reads the _delimiter_, reads and checks the _delimiter length_ field,
  /// and returns _true_.
  bool _isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem);

  /// Reads a Sequence with a defined length Value Field Length [vlf].
  SQ _readDSQ(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    assert(vlf != kUndefinedLength);
    final items = <Item>[];
    final sqEnd = _rb.index + vlf;
    while (_rb.index < sqEnd) {
      final item = _readItem();
      items.add(item);
    }
    if (sqEnd != _rb.index) warn('sqEnd($sqEnd) != rb.index(${_rb.index})');
    final dBytes = _makeLongDicomBytes(eStart);
    return makeSQFromBytes(cds, items, dBytes);
  }

  /// Returns [VFFragmentList] for a [kPixelData] Element.
  /// There are only three valid VRs for this method: OB, OW, UN.
  VFFragmentList _readEncapsulatedPixelData(
      int code, int eStart, int vrIndex, int vlf) {
    assert(vlf == kUndefinedLength && _isMaybeUndefinedLengthVR(vrIndex));
    final delimiter = _rb.readCode();
    if (delimiter == kItem) {
      return _readPixelDataFragments(code, eStart, vrIndex, vlf, delimiter);
    } else if (delimiter == kSequenceDelimitationItem) {
      // An Empty Pixel Data Element
      _checkDelimiterLength(delimiter);
      return null;
    } else {
      throw 'Non-Delimiter ${dcm(delimiter)}, $delimiter found';
    }
  }

  /// Reads the Fragments of an encapsulated (compressed) [kPixelData]
  /// [Element].
  ///
  /// Each Fragment starts with an Item Delimiter followed by the 32-bit Item
  /// length field, which may not have a value of kUndefinedValue.
  VFFragmentList _readPixelDataFragments(
      int code, int eStart, int vrIndex, int vlf, int itemDelimiter) {
    assert(code == kPixelData &&
        _isMaybeUndefinedLengthVR(vrIndex) &&
        itemDelimiter == kItem);
    _checkForOB(vrIndex, rds.transferSyntax);

    final fragments = <Uint8List>[];
    var delimiter = itemDelimiter;
    do {
      assert(delimiter == kItem, 'Invalid Item code: ${dcm(delimiter)}');
      final vlf = _rb.readUint32();
      assert(vlf != kUndefinedLength, 'Invalid length: ${dcm(vlf)}');

      final startOfVF = _rb.index;
      final endOfVF = _rb.rSkip(vlf);
      fragments.add(_rb.asUint8List(startOfVF, endOfVF - startOfVF));
      delimiter = _rb.readCode();
    } while (delimiter != kSequenceDelimitationItem);

    _checkDelimiterLength(delimiter);
    final v = VFFragmentList(fragments);
    return v;
  }

  void _checkDelimiterLength(int delimiter) {
    final vlf = _rb.readUint32();
    if (vlf != 0) warn('Encountered non-zero delimiter length($vlf)');
  }

  void _checkForOB(int vrIndex, TransferSyntax ts) {
    if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
      final vr = vrByIndex[vrIndex];
      warn('Invalid VR($vr) for Encapsulated TS: $ts');
    }
  }

  /// Reads a 32-bit Value Field Length field and throws an error if it
  /// is longer than [_rb].remaining.
  int _getVlf16() {
    final vlf = _rb.readUint16();
    if (vlf > _rb.remaining) _vlfError(vlf);
    return vlf;
  }

  void _vlfError(int vlf) {
    error('Value Field Length($vlf) is longer than'
        ' DicomReadBuffer remaining(${_rb.remaining})');
    if (throwOnError) throw ShortFileError();
  }

  /// Reads a 32-bit Value Field Length field and throws an error if it
  /// is longer than [_rb].remaining.
  int _getVlf32() {
    final vlf = _rb.readUint32();
    if (vlf > _rb.length && vlf != kUndefinedLength) {
      if (_afterPixelData) {
        throw DataAfterPixelDataError('@${_rb.index} *** after pixel data: '
            '${_rb.remaining} bytes remaining');
      }
      _vlfError(vlf);
    }
    return vlf;
  }

  bool _isSpecialVR(int vrIndex) =>
      vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

  bool _isMaybeUndefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRMaybeUndefinedIndexMin &&
      vrIndex <= kVRMaybeUndefinedIndexMax;

  // **** Logging Functions

  void error(String s) => log.error('**** @R${_rb.index} $s');
  void warn(String s) => log.warn('** @R${_rb.index} $s');

  // TODO: create no_logging_mixin and logging_mixin
  void _startElementMsg(int code, int eStart, int vrIndex, int vlf) {
    _checkVlf(vlf);
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vlf: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    log
      ..debug('>@R$eStart ${dcm(code)} $vrId($vrIndex) $len')
      ..down;
  }

  void _endElementMsg(Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    final s = '<@R${_rb.index} #$eNumber: $e';
    log
      ..up
      ..debug(s);
  }

  void _startSQMsg(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    _checkVlf(vlf);
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vlf: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    final tag = Tag.lookupByCode(code, vrIndex);
    if (tag.vrIndex != kSQIndex) warn('Read SQ with Non-Sequence Tag $tag');
    final msg = '>@R$eStart ${dcm(code)} $vrId($vrIndex) $len $tag';
    log
      ..debug(msg)
      ..down;
  }

  void _endSQMsg(SQ e) {
    final eNumber = '$count'.padLeft(4, '0');
    final msg = '<@R${_rb.index} #$eNumber: $e';
    log
      ..up
      ..debug(msg);
  }

  void _startDatasetMsg(
      int eStart, String name, int delimiter, int vlf, Dataset ds) {
    _checkVlf(vlf);
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vlf: $vlf';
    final dLimit = (delimiter == 0) ? 'No Delimiter' : dcm(delimiter);
    log
      ..debug('>@R$eStart $name $dLimit $len $ds')
      ..down;
  }

  void _endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds) {
    log
      ..up
      ..debug('<@R$dsStart $name $dsBytes: $ds');
  }

  void _startReadRootDataset(int rdsStart, int length) {
    _checkVlf(length);
    log
      ..down
      ..debug('>@R${_rb.index} subReadRootDataset length($length) $rds')
      ..down;
  }

  void _endReadRootDataset(RootDataset rds, RDSBytes dsBytes) {
    log
      ..up
      ..debug('! $dsBytes')
      ..debug('| $count Elements read');
    if (rds[kPixelData] == null)
      log.info('| ** Pixel Data Element not present');
    if (rds.hasDuplicates) warn('Duplicates Present in rds0');
    log
      ..debug('<@R${_rb.index} subReadRootDataset $dsBytes $rds')
      ..up
      ..debug('<@R${_rb.index} readRootDataset ${rds.total}');
  }

  void _checkVlf(int vlf) {
    if (vlf != kUndefinedLength && vlf.isOdd)
      error('Odd Value Length Field(vlf == $vlf)');
  }
/*
  // Urgent Jim test
  void convertVRUNImageElements(RootDataset rds, int vfOffset) {
    final bitsAllocated = rds.bitsAllocated;
    final e = rds.lookup(kPixelData);
    if (e == null) return;

    int vrIndex;
    if (bitsAllocated == 8 && e.vrIndex != kOBIndex) {
      vrIndex = kOBIndex;
    } else if (bitsAllocated == 16) {
      vrIndex = kOWIndex;
    } else {
      invalidElement(
          'Invalided Pixel Data $e\n  bitAllocated = $bitsAllocated', e);
    }
    if (e.vrIndex == vrIndex) return;

    VFFragments fragments;
    if (e is UNPixelData) {
      fragments = e.fragments;
    } else if (e is OBPixelData) {
      fragments = e.fragments;
    } else if (e is OWPixelData) {
      fragments = e.fragments;
    }
    final vfOffset = (e.isEvr)
    final npd = _makePixelData(e.code, e.vfBytes, e.vrIndex, e.vfOffset,
        e.vfLengthField, rds.transferSyntax, fragments);
    rds[kPixelData] = npd;
  }
*/

  @override
  String toString() => '$runtimeType: rds: $rds, cds: $cds';
}

abstract class EvrSubReader extends SubReader {
  EvrSubReader(Bytes bytes, DecodingParameters dParams, Dataset cds)
      : super(DicomReadBuffer(bytes), dParams, cds);

  /// Returns _true_ if reading an Explicit VR Little Endian file.
  @override
  bool get isEvr => true;

  /// Returns _true_ if the VR has a 16-bit Value Field Length field.
  bool _isEvrShortVR(int vrIndex) =>
      vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

  void readRootDataset(int fmiEnd) {
    assert(fmiEnd == _rb.index, 'fmiEnd: $fmiEnd rb.index: $_rb.index');
    if (ts == TransferSyntax.kExplicitVRBigEndian)
      _rb.buffer.endian = Endian.big;
    _readRootDataset(fmiEnd);
    if (doLogging) {
      final fmiCount = rds.fmi.length;
      final eCount = rds.elements.length;
      log
        ..debug('TS: $ts')
        ..debug('Fmi Elements: $fmiCount')
        ..debug('Evr Elements: $eCount')
        ..debug('Total:        ${rds.total}')
        ..debug('Duplicates:   ${rds.duplicates.length}')
        ..debug('Bytes read:   ${_rb.index} ');
    }
  }

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element _readElement() {
    final eStart = _rb.index;
    final code = _rb.readCode();
    final vrCode = _rb.readVRCode();
    final vrIndex = _lookupEvrVRIndex(code, eStart, vrCode);
    if (_isEvrShortVR(vrIndex)) {
      return _readDefinedLength(code, eStart, vrIndex, 8, _getVlf16());
    } else {
      _rb.rSkip(2);
      return _readLong(code, eStart, vrIndex, 12, _getVlf32());
    }
  }

  int _lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vrIndex = vrIndexFromCode(vrCode);
    if (vrIndex == null) {
      // TODO: this should throw
      _nullVRIndex(code, eStart, vrCode);
    } else if (_isSpecialVR(vrIndex)) {
      _changingVR(code, vrIndex);
      return kUNIndex;
    } else if (Tag.isPCCode(code) &&
        (vrIndex != kLOIndex && vrIndex != kUNIndex)) {
      _invalidPrivateCreator(code, vrIndex);
    }
    return vrIndex;
  }

  void _nullVRIndex(int code, int eStart, int vrCode) =>
      warn('eStart: $eStart ${dcm(code)} Null VR(${hex16(vrCode)}, $vrCode)');

  void _changingVR(int code, int vrIndex) =>
      warn('Changing (${hex32(code)}) with Special VR '
          '${vrIdFromIndex(vrIndex)}) to VR.kUN');

  void _invalidPrivateCreator(int code, int vrIndex) {
    assert(Tag.isPCCode(code) && (vrIndex != kLOIndex && vrIndex != kUNIndex));
    warn('Invalid Private Creator (${hex32(code)}) '
        '${vrIdFromIndex(vrIndex)}($vrIndex) should be VR.kLO');
  }

  /// Reads File Meta Information (FMI) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  int readFmi() {
    if (doLogging) log.debug('>@R${_rb.index} Reading FMI:', 1);
    if (_rb.index != 0)
      return invalidReadBufferIndex(_rb as ReadBuffer, _rb.index);

    if (!_readPrefix()) {
      _rb.rIndex = 0;
      if (doLogging) log.up;
      return 0;
    }
    assert(_rb.index == 132, 'Non-Prefix start index: ${_rb.index}');
    if (doLogging) log.down;
    while (_rb.isReadable) {
      final code = _rb.peekCode();
      if (code >= 0x00030000) break;
      final e = _readElement();
      rds.fmi[e.code] = e;
    }

    if (!_rb.rHasRemaining(dParams.shortFileThreshold - _rb.index)) {
      if (doLogging) log.up;
      throw EndOfDataError(
          '_readFmi', 'index: ${_rb.index} bdLength: ${_rb.length}');
    }

    _ts = rds.transferSyntax;
    if (!global.isSupportedTransferSyntax(ts.asString)) {
      log.up;
      return invalidTransferSyntax(ts);
    }
    if (dParams.targetTS != null && ts != dParams.targetTS) {
      log.up;
      return invalidTransferSyntax(ts, dParams.targetTS);
    }

    if (doLogging)
      log
        ..up
        ..debug('<R@${_rb.index} FinishedReading FMI:')
        ..up
        ..debug('|@${_rb.index} TS: $ts');
    return _rb.index;
  }

  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a
  /// PS3.10 DICOM File Format. Returns true if a valid Preamble
  /// and Prefix where read. Read as 32-bit integer. This is faster
  bool _readPrefix() {
    _rb.buffer.endian = Endian.little;
    if (_rb.index != 0) return false;
    _rb.rSkip(128);
    final prefix = _rb.readUint32();
    if (prefix == kDcmPrefix) return true;
    _rb.reset;
    _noDcmPrefixPresent(_rb.readUint8List(128), _rb.readUint8List(4));
    return false;
  }
}

void _noDcmPrefixPresent(Uint8List preamble, Uint8List prefix) =>
    log.warn('** No DICOM Prefix present:\n  $preamble\n  $prefix');

abstract class IvrSubReader extends SubReader {
  IvrSubReader(DicomReadBuffer rb, DecodingParameters dParams, Dataset cds)
      : super(rb, dParams, cds);

  @override
  bool get isEvr => false;

  /// The [DicomBytes] being read by _this_.
  @override
  DicomBytes get bytes => _rb.buffer;

  void readRootDataset(int fmiEnd) {
    assert(fmiEnd == _rb.index, 'fmiEnd: $fmiEnd != rb.index: ${_rb.index}');
    _readRootDataset(fmiEnd);
    if (doLogging) {
      final fmiCount = rds.fmi.length;
      final eCount = rds.elements.length;
      log
        ..debug('TS: $ts')
        ..debug('Fmi Elements: $fmiCount')
        ..debug('Ivr Elements: $eCount')
        ..debug('Total:        ${rds.total}')
        ..debug('Duplicates:   ${rds.duplicates.length}')
        ..debug('Bytes read:   ${_rb.index} ');
    }
  }

  @override
  Element _readElement() {
    final eStart = _rb.index;
    final code = _rb.readCode();
    final vlf = _getVlf32();

    var vrIndex = kUNIndex;
    Tag tag;
    if (doLookupVRIndex) {
      final token = (Tag.isPCCode(code)) ? _rb.getUtf8(vlf).trim() : '';
      tag = Tag.lookupByCode(code, vrIndex, token);
      if (tag != null && (tag.vrIndex <= kVRNormalIndexMax))
        vrIndex = tag.vrIndex;
    }
    return _readLong(code, eStart, vrIndex, 8, vlf);
  }
}

class InvalidDicomReadBufferIndex extends Error {
  final ReadBuffer _rb;
  final int index;

  InvalidDicomReadBufferIndex(this._rb, [int index])
      : index = index ?? _rb.index;

  @override
  String toString() => 'InvalidReadBufferIndex($index): $_rb';
}

// ignore: prefer_void_to_null
Null invalidReadBufferIndex(ReadBuffer rb, int index) =>
    throw InvalidDicomReadBufferIndex(rb, index);
