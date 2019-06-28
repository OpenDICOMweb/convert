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

import 'package:bytes_dicom/bytes_dicom.dart';
import 'package:core/core.dart';
import 'package:core/vf_fragments.dart';

import 'package:converter/src/binary/base/constants.dart';
import 'package:converter/src/binary/base/new_reader/no_logging_mixin.dart';
import 'package:converter/src/errors.dart';
import 'package:converter/src/decoding_parameters.dart';
import 'package:converter/src/element_offsets.dart';
import 'package:converter/src/parse_info.dart';

// ignore_for_file: public_member_api_docs
// ignore_for_file: avoid_positional_boolean_parameters, only_throw_errors
// ignore_for_file: avoid_catches_without_on_clauses

// Reader axioms
// 1. start is always the first byte of the Element being read
//    and eEnd is always the end of the Element [be]
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
    int code, int start, int vrIndex, int vlf);

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
  final DicomReadBuffer rb;

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
//  Element fromIndex(int code, int start, int eEnd, int vfl, int vrIndex);

  /// Creates an Element from [Bytes].
  Element fromBytes(int code, Bytes bytes, int vrIndex, int vfOffset);

  /// Returns a new [Element].
  // Note: Typically this may or may not be implemented.
  Element fromValues(int code, Iterable values, int vrIndex, [Bytes bytes]) =>
      unsupportedError();

  /// Returns a new Pixel Data [Element].
  Element makePixelData(int code, Bytes bytes, int vrIndex,
      [int vfLengthField, TransferSyntax ts, VFFragmentList vf]);

  /// Creates a new Sequence ([SQ]) [Element].
  SQ makeSequenceFromCode(int code, Dataset cds, Iterable items, int vfOffset,
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

  Uint8List get rootBytes => rb.asUint8List(rb.offset, rb.length);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  TransferSyntax get defaultTS => _defaultTS ??= rds.transferSyntax;
  TransferSyntax _defaultTS;

  /// Returns a new [Item], with not [Element].
  Item _makeEmptyItem(Dataset parent, [SQ sequence]) =>
      makeItem(parent, sequence, <int, Element>{});

  final String kItem32BitLEAsString = hex32(kItem32BitLE);

  RootDataset readRootDataset(int fmiEnd, TransferSyntax ts) {
    final rdsStart = rb.rIndex;
    final length = rb.readRemaining;

    if (doLogging)
      startReadRootDataset(rdsStart, length);
    _readDatasetDefinedLength(rds, rdsStart, length);
    final rdsLength = rb.rIndex - fmiEnd;
    final rdsBytes = rb.view(fmiEnd, rdsLength);
    final dsBytes = RDSBytes(rdsBytes, fmiEnd);
    rds.dsBytes = dsBytes;
    if (doLogging)
      endReadRootDataset(rds, dsBytes);
    return rds;
  }

  /// Reads and returns an [Item].
  Item _readItem([SQ sq]) {
    assert(rb.rHasRemaining(8));
    final iStart = rb.rIndex;

    // read 32-bit kItem code and Item length field
    final delimiter = rb.readUint32();
    if (delimiter != kItem32BitLE)
      throw 'Missing Item Delimiter';
    final vlf = _getVlf32();
    final item = _makeEmptyItem(cds);
    final parentDS = cds;
    cds = item;
    if (doLogging)
      startDatasetMsg(iStart, 'readItem', delimiter, vlf, cds);

    if (vlf == kUndefinedLength) {
      _readDatasetUndefinedLength(item, rb.rIndex);
    } else {
      if (vlf.isOdd)
        log.debug('Dataset with odd vfl($vlf)');
      _readDatasetDefinedLength(item, rb.rIndex, vlf);
    }

    final bd = rb.sublist(iStart, rb.rIndex);
    final dsBytes = IDSBytes(bd);
    item.dsBytes = dsBytes;
    cds = parentDS;
    if (doLogging)
      endDatasetMsg(rb.rIndex, 'readItem', dsBytes, item);
    return item;
  }

  // **** This is one of the only two places Elements are added to the dataset.
  // **** This is the other of the only two places Elements are added to
  // **** the dataset.

  // **** This is one of the only two places Elements are added to the dataset.
  void _readDatasetDefinedLength(Dataset ds, int dsStart, int vfl) {
    assert(vfl != kUndefinedLength && dsStart == rb.rIndex);
    final dsEnd = dsStart + vfl;
    while (rb.rIndex < dsEnd) {
      final e = _readElement();
      final ok = ds.tryAdd(e);
      if (!ok)
        log.warn('** duplicate: $e');
    }
  }

  void _readDatasetUndefinedLength(Dataset ds, int dsStart) {
    while (!_isItemDelimiter()) {
      // Elements are always read into the current dataset.
      // **** This is the only place they are added to the dataset.
      final e = _readElement();
      final ok = ds.tryAdd(e);
      if (!ok)
        log.warn('** duplicate: $e');
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
      if (rb.readUint16() != kDelimiterFirst16Bits ||
          rb.readUint16() != kSequenceDelimiterLast16Bits)
        continue;
      break;
    }
    final length = rb.readUint32();
    if (length != 0)
      log.warn('** Encountered non-zero delimiter length($length)');
  }

  /// Returns true if the [target] delimiter is found. If the target
  /// delimiter is found the _read index_ is advanced to the end
  /// of the delimiter field (8 bytes); otherwise, readIndex does not change.
  bool _checkForDelimiter(int target) {
    final delimiter = rb.bytes.getUint32(rb.rIndex);
    if (target == delimiter) {
      rb.rSkip(4);
      final length = rb.readUint32();
      if (length != 0)
        log.warn('** Encountered non-zero delimiter length($length)');
      return true;
    }
    return false;
  }

  /// Reads an returns an [Element] with a 32-bit Value Field. The
  /// [vfOffset] is 12 for EVR and 8 for IVR.
  Element _readLong(int code, int start, int vrIndex, int vfOffset, int vlf) {
    assert(rb.rIndex.isEven);
    if (vlf.isOdd && vlf != kUndefinedLength)
      log.error('Odd vlf: $vlf');
    // Read but don't advance index
    final delimiter = rb.bytes.getUint32(rb.rIndex);

    if (vrIndex == kSQIndex) {
      return _readSequence(code, start, vrIndex, vfOffset, vlf);
    } else if (vrIndex == kUNIndex &&
        delimiter == kItem32BitLE &&
        code != kPixelData) {
      final index = rb.rIndex;
      try {
        log.debug('** reading ${dcm(code)} vrIndex($vrIndex) vlf: $vlf');
        return _readSequence(code, start, vrIndex, vfOffset, vlf);
      } catch (e) {
        rb.rIndex = index;
        return (vlf == kUndefinedLength)
            ? _readLongUndefinedLength(code, start, vrIndex, vfOffset, vlf)
            : _readDefinedLength(code, start, vrIndex, vfOffset, vlf);
      }
    } else if (delimiter == kSequenceDelimitationItem32BitLE &&
        vlf == kUndefinedLength) {
      rb.rSkip(4);
      final items = <Item>[_makeEmptyItem(cds)];
      return makeSequenceFromCode(
          code, cds, items, vfOffset, kUndefinedLength, Bytes.kEmptyBytes);
    } else if (vlf == kUndefinedLength) {
      return _readLongUndefinedLength(code, start, vrIndex, vfOffset, vlf);
    } else {
      return _readDefinedLength(code, start, vrIndex, vfOffset, vlf);
    }
  }

  /// Called if the [vrIndex] is [kSQIndex]; or if the [vrIndex] is
  /// [kUNIndex] and the first 32 bits of the Value Field contain either
  /// [kItemDelimitationItem32BitLE] or [kSequenceDelimitationItem32BitLE].

  /// If it is a Sequence, it will start with either a [kItem32BitLE]
  /// delimiter or if it is an empty undefined length Sequence it will
  /// start with a kSequenceDelimiter.
  SQ _readSequence(int code, int start, int vrIndex, int vfOffset, int vlf) {
    if (vrIndex != kSQIndex) {
      if (vrIndex == kUNIndex) {
        log.warn('** Creating Sequence as UN(($vrIndex) ${dcm(code)}');
      } else {
        log.error('** Creating Sequence with vr($vrIndex) ${dcm(code)}');
      }
    }
    if (doLogging)
      startSQMsg(code, start, vrIndex, vfOffset, vlf);
    final sq = (vlf == kUndefinedLength)
        ? _readUSQ(code, start, kSQIndex, vfOffset, vlf)
        : _readDSQ(code, start, kSQIndex, vfOffset, vlf);
    _count++;
    if (doLogging)
      endSQMsg(sq);
    return sq;
  }

  /// Reads a Sequence with a Value Field Length [vfl]
  /// containing [kUndefinedLength].
  SQ _readUSQ(int code, int start, int vrIndex, int vfOffset, int vfl) {
    assert(vfl == kUndefinedLength);
    final items = <Item>[];
    while (!_isSequenceDelimiter()) {
      final item = _readItem();
      items.add(item);
    }
    final bytes = rb.sublist(start, rb.rIndex);
    return makeSequenceFromCode(code, cds, items, vfOffset, vfl, bytes);
  }

  /// If the sequence delimiter is found at the current _read index_,
  /// reads the _delimiter_, reads and checks the _delimiter length_ field,
  /// and returns _true_.
  bool _isSequenceDelimiter() =>
      _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  /// Reads a Sequence with a defined length Value Field Length [vfl].
  SQ _readDSQ(int code, int start, int vrIndex, int vfOffset, int vfl) {
    assert(vfl != kUndefinedLength);
    final items = <Item>[];
    final sqEnd = rb.rIndex + vfl;
    while (rb.rIndex < sqEnd) {
      final item = _readItem();
      items.add(item);
    }
    if (sqEnd != rb.rIndex)
      log.warn('** sqEnd($sqEnd) != rb.rIndex(${rb.rIndex})');
    final bytes = rb.sublist(start, sqEnd);
    return makeSequenceFromCode(code, cds, items, vfOffset, vfl, bytes);
  }

  /// Reads an Element with a 32-bit Value Field Length Field [vlf]
  /// containing [kUndefinedLength] (which is not a Sequence ([SQ]}).
  ///
  /// Only three non-Sequence [Element]s can have Value Field Length
  /// Field [vlf] containing [kUndefinedLength] OB, OW, and UN.
  Element _readLongUndefinedLength(
      int code, int start, int vrIndex, int vfOffset, int vlf) {
    if (doLogging)
      startElementMsg(code, start, vrIndex, vlf);
    assert(vlf == kUndefinedLength && isMaybeUndefinedLengthVR(vrIndex));
    assert(vrIndex != kSQIndex);
    VFFragmentList vf;
    if (code == kPixelData) {
      vf = _readEncapsulatedPixelData(code, start, vrIndex, vlf);
      assert(vf != null);
    } else {
      _findEndOfULengthVF();
    }
    final bytes = rb.sublist(start, rb.rIndex);
    final e = (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex, vlf, defaultTS, vf)
        : fromBytes(code, bytes, vrIndex, vfOffset);
    _count++;
    if (doLogging)
      endElementMsg(e);
    return e;
  }

  /// Return a defined length Element with a long Value Field
  Element _readDefinedLength(
      int code, int start, int vrIndex, int vfOffset, int vlf) {
    if (doLogging)
      startElementMsg(code, start, vrIndex, vlf);
    rb.rSkip(vlf);
    final bytes = rb.sublist(start, rb.rIndex);
    final e = (code == kPixelData)
        ? makePixelData(code, bytes, vrIndex, vfOffset)
        : fromBytes(code, bytes, vrIndex, vfOffset);
    _count++;
    if (doLogging)
      endElementMsg(e);
    return e;
  }

  /// Returns [VFFragmentList] for a [kPixelData] Element.
  /// There are only three valid VRs for this method: OB, OW, UN.
  VFFragmentList _readEncapsulatedPixelData(
      int code, int start, int vrIndex, int vlf) {
    assert(vlf == kUndefinedLength);
    assert(isMaybeUndefinedLengthVR(vrIndex));
    final delimiter = rb.bytes.getUint32(rb.rIndex);
    if (delimiter == kItem32BitLE) {
      return _readPixelDataFragments(code, start, vrIndex, vlf);
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
    if (vlf != 0)
      log.warn('** Encountered non-zero delimiter length($vlf)');
  }

  /// Reads an encapsulated (compressed) [kPixelData] [Element].
  VFFragmentList _readPixelDataFragments(
      int code, int start, int vrIndex, int vlf) {
    assert(isMaybeUndefinedLengthVR(vrIndex));
    _checkForOB(vrIndex, rds.transferSyntax);
    return _readFragments(code, vrIndex, vlf);
  }

  void _checkForOB(int vrIndex, TransferSyntax ts) {
    if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
      final vr = vrByIndex[vrIndex];
      log.warn('** Invalid VR($vr) for Encapsulated TS: $ts');
    }
  }

  /// Read Pixel Data Fragments.
  /// They each start with an Item Delimiter followed by the 32-bit Item
  /// length field, which may not have a value of kUndefinedValue.
  VFFragmentList _readFragments(int code, int vrIndex, int vlf) {
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
    final v = VFFragmentList(fragments);
    return v;
  }

  /// Reads a 32-bit Value Field Length field and throws an error if it
  /// is longer than [rb].remaining.
  int _getVlf16() {
    final vlf = rb.readUint16();
    if (vlf > rb.readRemaining) _vlfError(vlf);
    return (vlf.isOdd) ? vlf + 1 : vlf;
  }

  void _vlfError(int vlf) {
    log.error('Value Field Length($vlf) is longer than'
        ' ReadBuffer remaining(${rb.readRemaining})');
    if (throwOnError) throw ShortFileError();
  }

  /// Reads a 32-bit Value Field Length field and throws an error if it
  /// is longer than [rb].remaining.
  int _getVlf32() {
    final vlf = rb.readUint32();
    if (vlf > rb.length && vlf != kUndefinedLength) _vlfError(vlf);
    return (vlf.isOdd) ? vlf + 1 : vlf;
  }

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

/*

  // **** Logging Functions
  // TODO: create no_logging_mixin and logging_mixin
  void startElementMsg(int code, int start, int vrIndex, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    log..debug('>@R$start ${dcm(code)} $vrId($vrIndex) $len')..down;
  }

  void endElementMsg(Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    log..up..debug('<@R${rb.rIndex} $eNumber: $e');
  }

  void startSQMsg(int code, int start, int vrIndex, int vfOffset, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    final tag = Tag.lookupByCode(code, vrIndex);
    if (tag.vrIndex != kSQIndex) log.warn('Read SQ with Non-Sequence Tag $tag');
    final msg = '>@R$start ${dcm(code)} $vrId($vrIndex) $len $tag';
    log.debug(msg);
  }

  void endSQMsg(SQ e) {
    final eNumber = '$count'.padLeft(4, '0');
    final msg = '<@R${rb.rIndex} $eNumber: $e';
    log.debug(msg);
  }

  void startDatasetMsg(
      int start, String name, int delimiter, int vlf, Dataset ds) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final dLimit = (delimiter == 0) ? 'No Delimiter' : dcm(delimiter);
    log..debug('>@R$start $name $dLimit $len $ds', 1)..down;
  }

  void endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds) {
    log..up..debug('>@R$dsStart $name $dsBytes: $ds', -1);
  }

  void startReadRootDataset(int rdsStart, int length) =>
      log..debug('>@${rb.rIndex} subReadRootDataset length($length) $rds')
      ..down;

  void endReadRootDataset(RootDataset rds, RDSBytes dsBytes) {
    log..up..debug('>@${rb.rIndex} subReadRootDataset $dsBytes $rds')
      ..debug('$count Elements read');
    if (rds[kPixelData] == null) log.info('** Pixel Data Element not present');
    if (rds.hasDuplicates) log.warn('** Duplicates Present in rds0');
  }
*/

  @override
  String toString() => '$runtimeType: rds: $rds, cds: $cds';

  // **** Logging Interface
  void startElementMsg(int code, int start, int vrIndex, int vlf);

  void endElementMsg(Element e);

  void startSQMsg(int code, int start, int vrIndex, int vfOffset, int vlf);

  void endSQMsg(SQ e) {}

  void startDatasetMsg(
      int start, String name, int delimiter, int vlf, Dataset ds);

  void endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds);

  void startReadRootDataset(int rdsStart, int length);

  void endReadRootDataset(RootDataset rds, RDSBytes dsBytes);
}

class InvalidReadBufferIndex extends Error {
  final DicomReadBuffer rb;
  final int index;

  InvalidReadBufferIndex(this.rb, [int index]) : index = index ?? rb.rIndex;

  @override
  String toString() => 'InvalidReadBufferIndex($index): $rb';
}

abstract class EvrSubReader extends SubReader with NoLoggingMixin {
  /// The [Bytes] being read by _this_.
  @override
  final BytesDicom bytes;

  EvrSubReader(this.bytes, DecodingParameters dParams, Dataset cds)
      : super(DicomReadBuffer(bytes), dParams, cds);

  /// Returns _true_ if reading an Explicit VR Little Endian file.
  @override
  bool get isEvr => true;

  /// Returns _true_ if the VR has a 16-bit Value Field Length field.
  bool _isEvrShortVR(int vrIndex) => vrIndex >= kAEIndex && vrIndex <= kUSIndex;

  /// For EVR Datasets, all Elements are read by this method.
  @override
  Element _readElement() {
    final start = rb.rIndex;
    final code = rb.readCode();
    final vrCode = rb.readUint16();
    final vrIndex = _lookupEvrVRIndex(code, start, vrCode);
    if (_isEvrShortVR(vrIndex)) {
      return _readDefinedLength(code, start, vrIndex, 8, _getVlf16());
    } else {
      rb.rSkip(2);
      return _readLong(code, start, vrIndex, 12, _getVlf32());
    }
  }

  int _lookupEvrVRIndex(int code, int start, int vrCode) {
    final vrIndex = vrIndexFromCode(vrCode);
    if (vrIndex == null) {
      // TODO: this should throw
      _nullVRIndex(code, start, vrCode);
    } else if (isSpecialVRIndex(vrIndex)) {
      log.warn('** Changing (${hex32(code)}) with Special VR '
          '${vrIdFromIndex(vrIndex)}) to VR.kUN');
      return kUNIndex;
    } else if (Tag.isPCCode(code) &&
        (vrIndex != kLOIndex && vrIndex != kUNIndex)) {
      _invalidPrivateCreator(code, vrIndex);
    }
    return vrIndex;
  }

  void _nullVRIndex(int code, int start, int vrCode) {
    log.warn('** @$start ${dcm(code)} Null VR(${hex16(vrCode)}, $vrCode)');
  }

  void _invalidPrivateCreator(int code, int vrIndex) {
    assert(Tag.isPCCode(code) && (vrIndex != kLOIndex && vrIndex != kUNIndex));
    log.warn('** Invalid Private Creator (${hex32(code)}) '
        '${vrIdFromIndex(vrIndex)}($vrIndex) should be VR.kLO');
  }

  /// Reads File Meta Information (FMI) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  int readFmi() {
    if (doLogging) log.debug('>@${rb.rIndex} Reading FMI:', 1);
    if (rb.rIndex != 0) throw InvalidReadBufferIndex(rb);
    assert(rb.rIndex == 0, 'Non-Zero Read Buffer Index');
    if (!_readPrefix(rb)) {
      rb.rIndex = 0;
      if (doLogging) log.up;
      return -1;
    }
    assert(rb.rIndex == 132, 'Non-Prefix start index: ${rb.rIndex}');
    if (doLogging) log.down;
    while (rb.isReadable) {
      final code = rb.code;
      if (code >= 0x00030000) break;
      final e = _readElement();
      rds.fmi[e.code] = e;
    }

    if (!rb.rHasRemaining(dParams.shortFileThreshold - rb.rIndex)) {
      if (doLogging) log.up;
      throw EndOfDataError(
          '_readFmi', 'index: ${rb.rIndex} bdLength: ${rb.length}');
    }

    final ts = rds.transferSyntax;
    if (doLogging) log.debug('TS: $ts', -1);

    if (!global.isSupportedTransferSyntax(ts.asString)) {
      log.up;
      return invalidTransferSyntax(ts);
    }
    if (dParams.targetTS != null && ts != dParams.targetTS) {
      log.up;
      return invalidTransferSyntax(ts, dParams.targetTS);
    }

    if (doLogging) log.debug('<R@${rb.rIndex} FinishedReading FMI:', -1);
    return rb.rIndex;
  }

  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a
  /// PS3.10 DICOM File Format. Returns true if a valid Preamble
  /// and Prefix where read.
  bool _readPrefix(DicomReadBuffer rb) {
    if (rb.rIndex != 0) return false;
    return _isDcmPrefixPresent(rb);
  }

  /// Read as 32-bit integer. This is faster
  bool _isDcmPrefixPresent(DicomReadBuffer rb) {
    rb.rSkip(128);
    final prefix = rb.readUint32();
    if (prefix == kDcmPrefix) return true;
    log.warn('** No DICOM Prefix present');
    return false;
  }
}

abstract class IvrSubReader extends SubReader with NoLoggingMixin {
  final bool doLookupVRIndex;
  IvrSubReader(DicomReadBuffer rb, DecodingParameters dParams, Dataset cds,
      this.doLookupVRIndex)
      : super(rb, dParams, cds);

  @override
  bool get isEvr => false;

  /// The [Bytes] being read by _this_.
  @override
  Bytes get bytes => rb.bytes;

  @override
  Element _readElement() {
    final start = rb.rIndex;
    final code = rb.readCode();
    final tag = doLookupVRIndex ? _lookupTag(code, start) : null;
    final vrIndex = (tag == null) ? kUNIndex : tag.vrIndex;
    final vlf = _getVlf32();
    return _readLong(code, start, vrIndex, 8, vlf);
  }

  Tag _lookupTag(int code, int start, [int vrIndex, Object token]) {
    // Urgent Fix
    if (isPublicCode(code)) {
      return Tag.lookupByCode(code);
    } else if (Tag.isPDCode(code)) {
      // **** temporary
      return Tag.lookupByCode(code);
    } else if (Tag.isPCCode(code)) {
      return Tag.lookupByCode(code);
    } else {
      log.error('Unknown code: ${dcm(code)}');
      return Tag.lookupByCode(code);
    }
  }
}
