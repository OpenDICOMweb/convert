// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
library odw.sdk.convert.binary.reader;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/binary/base/reader/reader_interface_old.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';

part 'package:dcm_convert/src/binary/base/reader/read_evr.dart';
part 'package:dcm_convert/src/binary/base/reader/read_fmi.dart';
part 'package:dcm_convert/src/binary/base/reader/read_ivr.dart';
part 'package:dcm_convert/src/binary/base/reader/read_root.dart';

// Reader axioms
// 1. The read index (rIndex) should always be at the last place read,
//    and the end of the value field should be calculated by subtracting
//    the length of the delimiter (and delimiter length), which is 8 bytes.
//
// 2. For non-sequence Elements with undefined length (kUndefinedLength)
//    the Value Field Length (vfLength) of a non-Sequence Element.
//    The read index rIndex is left at the end of the Element Delimiter.

//TODO: redoc to reflect current state of code

typedef Element ElementMaker(EBytes eb, int vrIndex);

typedef PixelData PixelDataMaker(EBytes eb, int vrIndex,
    [TransferSyntax ts, VFFragments fragments]);

typedef SQ SequenceMaker(EBytes eb, Dataset cds, List<Item> items);

typedef Item ItemMaker(Dataset cds);

typedef Element EReader();

ElementMaker elementMaker;
PixelDataMaker pixelDataMaker;
SequenceMaker sequenceMaker;
ItemMaker itemMaker;

/// Returns the [ByteData] that was actually read, i.e. from 0 to
/// end of last [Element] read.
//ByteData bdRead;

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
abstract class DcmReaderBase extends DcmReaderInterface {
  /// The source of the [Uint8List] being read.
  final String path;

  @override
  final ReadBuffer rb;
  @override
  final RootDataset rds;

  ByteData fmiBD;

  /// If true the [ByteData] buffer ([rb] will be reused.
  final bool reUseBD;
  final DecodingParameters dParams;
  @override
  Dataset cds;

  /// The [ByteData] being read.
  // final int bdLength;

  /// Creates a new [DcmReaderBase]  where [rb].rIndex = 0.
  DcmReaderBase(ByteData bd, this.rds,
      {this.path = '', this.reUseBD = true, this.dParams = DecodingParameters.kNoChange})
      : rb = new ReadBuffer(bd);

  DcmReaderBase.from(DcmReaderBase rBase)
      : path = rBase.path,
        rb = rBase.rb,
        rds = rBase.rds,
        cds = rBase.cds,
        fmiBD = rBase.fmiBD,
        reUseBD = rBase.reUseBD,
        dParams = rBase.dParams;

  bool get isEvr => rds.isEvr;

  bool get isReadable => rb.isReadable;

  Uint8List get rootBytes => rb.buffer.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  bool hasRemaining(int n) => rb.hasRemaining(n);

/*
  @override
  RootDataset read() {
	  cds = rds;
	  if (!readFmi(rds)) return null;
	  return readRootDataset();
  }
*/

  void readRootDataset() {
    cds = rds;
    final hasFmi = readFmi(rds);
    __readRootDataset(eReader);
  }

  @override
  ByteData readFmi(RootDataset rds); => _readFmi(rb, rds, dParams);

  @override
  Element readDefinedLength(
          int code, int eStart, int vrIndex, int vlf, EBMaker ebMaker) =>
      __readDefinedLength(code, eStart, vrIndex, vlf, ebMaker);

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem32Bit] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  bool isSequenceVR(int vrIndex) => vrIndex == 0;

  bool isSpecialVR(int vrIndex) =>
      vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

  bool isNormalVR(int vrIndex) =>
      vrIndex >= kVRNormalIndexMin && vrIndex <= kVRNormalIndexMax;

  bool isMaybeUndefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

  bool isEvrLongVR(int vrIndex) =>
      vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

  bool isIvrDefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

  final String kItemAsString = hex32(kItem32BitLE);

  void __readRootDataset(EReader eReader) =>
      _readDatasetDefinedLength(rds, rb.rIndex, rb.remaining, eReader);

  /// Returns an [Item].
  // rIndex is @ delimiterFvr
  Item readItem(EReader eReader, int count) {
    assert(rb.hasRemaining(8));
    final iStart = rb.rIndex;

    // read 32-bit kItem code and Item length field
    final delimiter = rb.getUint32(rb.rIndex);
    if (delimiter != kItem32BitLE) throw 'Missing Item Delimiter';
    rb + 4;
    final vfLengthField = rb.uint32;
    // readItemStart('Reading Item', ount , vfLengthField', 1);c

    final item = itemMaker(cds);
    final parentDS = cds;
    cds = item;

    (vfLengthField == kUndefinedLength)
        ? _readDatasetUndefinedLength(item, eReader)
        : _readDatasetDefinedLength(item, rb.rIndex, vfLengthField, eReader);

    cds = parentDS;
    final bd = rb.buffer.asByteData(iStart, rb.rIndex - iStart);
    item.dsBytes = new IDSBytes(bd);
    return item;
  }

  // **** This is one of the only two places Elements are added to the dataset.
  void _readDatasetDefinedLength(Dataset ds, int dsStart, int vfLength, EReader eReader) {
    assert(vfLength != kUndefinedLength);
    final dsEnd = dsStart + vfLength;
    assert(dsStart == rb.rIndex);
    while (rb.rIndex < dsEnd) {
      // Elements are always read into the current dataset.
      final e = eReader();
      final ok = ds.tryAdd(e);
      if (!ok) log.warn('*** duplicate: $e');
    }
  }

  // **** This is the other of the only two places Elements are added to the dataset.
  void _readDatasetUndefinedLength(Dataset ds, EReader eReader) {
    while (!__isItemDelimiter()) {
      // Elements are always read into the current dataset.
      // **** This is the only place they are added to the dataset.
      final e = eReader();
      final ok = ds.tryAdd(e);
      if (!ok) log.warn('*** duplicate: $e');
    }
  }

  /// If the item delimiter _kItemDelimitationItem32Bit_, reads and checks the
  /// _delimiter length_ field, and returns _true_.
  bool __isItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

/*
  /// Read a Sequence.
  Element readSQ(int code, int eStart, int vlf, EBMaker ebMaker, EReader eReader) =>
      (vlf == kUndefinedLength)
          ? _readUSQ(code, eStart, vlf, ebMaker, eReader)
          : _readDSQ(code, eStart, vlf, ebMaker, eReader);
*/

  /// Reads a [kUndefinedLength] Sequence.
  Element readUSQ(int code, int eStart, int uLength, EBMaker ebMaker, EReader eReader) {
    assert(uLength == kUndefinedLength);
    final items = <Item>[];
    var itemCount = 0;
    while (!__isSequenceDelimiter()) {
      final item = readItem(eReader, itemCount);
      items.add(item);
      itemCount++;
    }
    return _makeSequence(code, eStart, ebMaker, items);
  }

  /// Reads a defined [vfLength].
  Element readDSQ(int code, int eStart, int vfLength, EBMaker ebMaker, EReader eReader) {
    assert(vfLength != kUndefinedLength);
    final items = <Item>[];
    final vfStart = rb.rIndex;
    final eEnd = vfStart + vfLength;

    var itemCount = 0;
    while (rb.rIndex < eEnd) {
      final item = readItem(eReader, itemCount);
      items.add(item);
      itemCount++;
    }
    final end = rb.rIndex;
    assert(eEnd == end, '$eEnd == $end');
    return _makeSequence(code, eStart, ebMaker, items);
  }

  // If VR is UN then this might be a Sequence
  Element __tryReadUNSequence(
      int code, int eStart, int vlf, EBMaker ebMaker, EReader eReader) {
    final delimiter = rb.getUint32(rb.rIndex);
    if (delimiter == kSequenceDelimitationItem32BitLE) {
      // An empty Sequence
      _readAndCheckDelimiterLength();
      return _makeSequence(code, eStart, EvrLong.make, emptyItemList);
    } else if (delimiter == kItem) {
      // A non-empty Sequence
      _readAndCheckDelimiterLength();
      return readSQ(code, eStart, vlf, EvrLong.make, eReader);
    }
    return null;
  }

  Element _makeSequence(int code, int eStart, EBMaker ebMaker, List<Item> items) {
    final eb = _makeEBytes(eStart, ebMaker);
    return sequenceMaker(eb, cds, items);
  }

  /// If the sequence delimiter is found at the current _read index_, reads the
  /// _delimiter_, reads and checks the _delimiter length_ field, and returns _true_.
  bool __isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  /// Returns the Value Field Length (vfLength) of a non-Sequence Element.
  /// The _read index_ is left at the end of the Element Delimiter.
  //  The [_rIndex] should be at the beginning of the Value Field.
  // Note: Since for binary DICOM the Value Field is 16-bit aligned,
  // it must be checked 16 bits at a time.
  int _findEndOfULengthVF() {
    while (rb.isReadable) {
      if (uint16 != kDelimiterFirst16Bits) continue;
      if (uint16 != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    _readAndCheckDelimiterLength();
    final endOfVF = rb.rIndex - 8;
    return endOfVF;
  }

  /// Returns true if the [target] delimiter is found. If the target
  /// delimiter is found the _read index_ is advanced to the end of the delimiter
  /// field (8 bytes); otherwise, readIndex does not change.
  bool _checkForDelimiter(int target) {
    final delimiter = rb.uint32Peek;
    if (target == delimiter) {
      rb + 4;
      _readAndCheckDelimiterLength();
      return true;
    }
    return false;
  }

  void _readAndCheckDelimiterLength() {
    final length = rb.uint32;
    log.debug2('${rb.rmm} ** Delimiter Length: $length');
    if (length != 0) {
      rb.warn('Encountered non-zero delimiter length($length) ${rb.rrr}');
    }
  }

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element readMaybeUndefinedLength(int code, int eStart, int vrIndex, int vlf,
      EBytes ebMaker(ByteData bd), EReader eReader) {
    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex) {
      final e = __tryReadUNSequence(code, eStart, vlf, ebMaker, eReader);
      if (e != null) return e;
    }
    return (vlf == kUndefinedLength)
        ? __readUndefinedLength(code, eStart, vrIndex, vlf, ebMaker)
        : __readDefinedLength(code, eStart, vrIndex, vlf, ebMaker);
  }

  // Finish reading an EVR Long Defined Length Element
  Element __readDefinedLength(
      int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
    assert(vlf != kUndefinedLength);
    rb + vlf;
    return (code == kPixelData)
        ? _makePixelData(code, eStart, vrIndex, rb.rIndex, false, ebMaker)
        : makeElement(code, eStart, vrIndex, rb.rIndex, ebMaker);
  }

  // Finish reading an EVR Long Undefined Length Element
  Element __readUndefinedLength(
      int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
    assert(vlf == kUndefinedLength);
    if (code == kPixelData) {
      return __readEncapsulatedPixelData(code, eStart, vrIndex, vlf, ebMaker);
    } else {
      final endOfVF = _findEndOfULengthVF();
      return makeElement(code, eStart, vrIndex, endOfVF, ebMaker);
    }
  }

  /// There are only three VRs that use this: OB, OW, UN
  // _rIndex is Just after vflengthField
  Element __readEncapsulatedPixelData(
      int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
    assert(vlf == kUndefinedLength);
    assert(_isMaybeUndefinedLengthVR(vrIndex));

    final delimiter = rb.getUint32(rb.rIndex);
    if (delimiter == kItem32BitLE) {
      return __readPixelDataFragments(code, eStart, vlf, vrIndex, ebMaker);
    } else if (delimiter == kSequenceDelimitationItem32BitLE) {
      // An Empty Pixel Data Element
      _readAndCheckDelimiterLength();
      return _makePixelData(code, eStart, vrIndex, rb.rIndex, true, ebMaker);
    } else {
      throw 'Non-Delimiter ${dcm(delimiter)}, $delimiter found';
    }
  }

  /// Reads an encapsulated (compressed) [kPixelData] [Element].
  Element __readPixelDataFragments(
      int code, int eStart, int vfLengthField, int vrIndex, EBytes ebMaker(ByteData bd)) {
    log.debug2('${rb.rmm} readPixelData Fragments', 1);
    assert(_isMaybeUndefinedLengthVR(vrIndex));
    __checkForOB(vrIndex, rds.transferSyntax);

    final fragments = __readFragments();
    log.debug3('${rb.ree}  read Fragments: $fragments', -1);
    return _makePixelData(code, eStart, vrIndex, rb.rIndex, true, ebMaker, fragments);
  }

  void __checkForOB(int vrIndex, TransferSyntax ts) {
    if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
      final vr = VR.lookupByIndex(vrIndex);
      rb.warn('Invalid VR($vr) for Encapsulated TS: $ts ${rb.rrr}');
    }
  }

  /// Read Pixel Data Fragments.
  /// They each start with an Item Delimiter followed by the 32-bit Item
  /// length field, which may not have a value of kUndefinedValue.
  VFFragments __readFragments() {
    final fragments = <Uint8List>[];
    var delimiter = rb.uint32;
    do {
      assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
      final vlf = rb.uint32;
      assert(vlf != kUndefinedLength, 'Invalid length: ${dcm(vlf)}');

      final startOfVF = rb.rIndex;
      final endOfVF = rb + vlf;
      fragments.add(rb.buffer.asUint8List(startOfVF, endOfVF - startOfVF));
      delimiter = rb.uint32;
    } while (delimiter != kSequenceDelimitationItem32BitLE);

    _checkDelimiterLength(delimiter);
    final v = new VFFragments(fragments);
    return v;
  }

  void _checkDelimiterLength(int delimiter) {
    final vfLengthField = rb.uint32;
    if (vfLengthField != 0)
      rb.warn('Delimiter has non-zero '
          'value: $delimiter/0x${hex32(delimiter)} ${rb.rrr}');
  }

  // vfLength cannot be undefined.
  Element makeElement(
      int code, int eStart, int vrIndex, int endOfVF, EBytes ebMaker(ByteData bd)) {
    assert(endOfVF != kUndefinedLength);
    final eb = _makeEBytes(eStart, ebMaker);
    return elementMaker(eb, vrIndex);
  }

  PixelData _makePixelData(
      int code, int eStart, int vrIndex, int endOfVF, bool undefined, EBMaker ebMaker,
      [VFFragments fragments]) {
    //_beyondPixelData = true;
    final eb = _makeEBytes(eStart, ebMaker);
    //  _beyondPixelData = true;
    return pixelDataMaker(eb, vrIndex, rds.transferSyntax, fragments);
  }

  EBytes _makeEBytes(int eStart, EBytes ebMaker(ByteData bd)) =>
      ebMaker(rb.buffer.asByteData(eStart, rb.rIndex - eStart));

  Tag checkCode(int code, int eStart) {
    final tag = Tag.lookup(code);
    if (tag == null) {
      rb.warn('Tag is Null: ${dcm(code)} start: $eStart ${rb.rrr}');
      showNext(rb.rIndex - 4);
    }
    return tag;
  }
/*
  //TODO: check the performance cost of code checking
  Tag checkCode(int code, int eStart) {
    if (_checkCode) {
      if (code < 0x00020000 || code >= kItem) {
        if (_beyondPixelData) {
          log.warn('** Bad data beyond Pixel Data');
          if (throwOnError)
            return invalidTagError('code${dcm(code)} @${eStart - 4} +${rb.remaining}');
        }
        log.error('Invalid Tag code: ${dcm(code)}');
        showReadIndex(rb.rIndex - 6);
        throw 'bad code';
      }
      if (code <= 0) _zeroEncountered(code);
      // Check for Group Length Code
      final elt = code & 0xFFFF;
      if (code > 0x3000 && (elt == 0)) _pInfo.hadGroupLengths = true;
    }

    final tag = Tag.lookup(code);
    if (tag == null) {
      rb.warn('Tag is Null: ${dcm(code)} start: $eStart ${rb.rrr}');
      showNext(rb.rIndex - 4);
    }
    return tag;
  }
*/

  int __vrToIndex(int code, VR vr) {
    var vrIndex = vr.index;
    if (_isSpecialVR(vrIndex)) {
      log.info1('-- Changing Special VR ${VR.lookupByIndex(vrIndex)}) to VR.kUN');
      vrIndex = VR.kUN.index;
    }
    return vrIndex;
  }

  bool __isValidVR(int code, int vrIndex, Tag tag) {
    if (vrIndex == kUNIndex) {
      log.debug3('${rb.rmm} VR ${VR.kUN} is valid for $tag');
      return true;
    }
    if (tag.hasNormalVR && vrIndex == tag.vrIndex) return true;
    if (tag.hasSpecialVR && tag.vr.isValidVRIndex(vrIndex)) {
      log.debug3('VR ${VR.lookupByIndex(vrIndex)} is valid for $tag');
      return true;
    }
    log.error('**** vrIndex $vrIndex is not valid for $tag');
    return false;
  }

  bool isNotValidVR(int code, int vrIndex, Tag tag) => !__isValidVR(code, vrIndex, tag);

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
      throw new EndOfDataError('Zero encountered ${rb.rrr}');

  String failedTSErrorMsg(String path, Error x) => '''
Invalid Transfer Syntax: "$path"\nException: $x\n ${rb.rrr}
    File length: ${rb.lengthInBytes}\n${rb.rrr} readFMI catch: $x
''';

  String failedFMIErrorMsg(String path, Object x) => '''
Failed to read FMI: "$path"\nException: $x\n'
	  File length: ${rb.lengthInBytes}\n${rb.rrr} readFMI catch: $x');
''';

  // Issue:
  // **** Below this level is all for debugging and can be commented out for
  // **** production.

  void showNext(int start) {
    if (isEvr) {
      _showShortEVR(start);
      _showLongEVR(start);
      _showIVR(start);
      _showShortEVR(start + 4);
      _showLongEVR(start + 4);
      _showIVR(start + 4);
    } else {
      _showIVR(start);
      _showIVR(start + 4);
    }
  }

  void _showShortEVR(int start) {
    if (rb.hasRemaining(8)) {
      final code = rb.getCode(start);
      final vrCode = rb.getUint16(start + 4);
      final vr = VR.lookupByCode(vrCode);
      final vfLengthField = rb.getUint16(start + 6);
      log.debug('${rb.rmm} **** Short EVR: ${dcm(code)} $vr vfLengthField: '
          '$vfLengthField');
    }
  }

  void _showLongEVR(int start) {
    if (rb.hasRemaining(8)) {
      final code = rb.getCode(start);
      final vrCode = rb.getUint16(start + 4);
      final vr = VR.lookupByCode(vrCode);
      final vfLengthField = rb.getUint32(start + 8);
      log.debug(
          '${rb.rmm} **** Long EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
    }
  }

  void _showIVR(int start) {
    if (rb.hasRemaining(8)) {
      final code = rb.getCode(start);
      final tag = Tag.lookupByCode(code);
      if (tag != null) log.debug(tag);
      final vfLengthField = rb.getUint16(start + 4);
      log.debug('${rb.rmm} **** IVR: ${dcm(code)} vfLengthField: $vfLengthField');
    }
  }

  String toVFLength(int vfl) => 'vfLengthField($vfl, ${hex32(vfl)})';
  String toHadULength(int vfl) =>
      'HadULength(${(vfl == kUndefinedLength) ? 'true': 'false'})';

  void showReadIndex([int index, int before = 20, int after = 28]) {
    index ??= rb.rIndex;
    if (index.isOdd) {
      rb.warn('**** Index($index) is not at even offset ADDING 1');
      index++;
    }

    for (var i = index - before; i < index; i += 2) {
      log.debug('$i:   ${hex16(rb.getUint16 (i))} - ${rb.getUint16 (i)}');
    }

    log.debug('** ${hex16(rb.getUint16 (index))} - ${rb.getUint16 (index)}');

    for (var i = index + 2; i < index + after; i += 2) {
      log.debug('$i: ${hex16(rb.getUint16 (i))} - ${rb.getUint16 (i)}');
    }
  }

  /*
//Enhancement:
void _printTrailingData(int start, int length) {
  for (var i = start; i < start + length; i += 4) {
    final x = rb.getUint16(i);
    final y = rb.getUint16(i + 2);
    final z = rb.getUint32(i);
    final xx = hex8(x);
    final yy = hex16(y);
    final zz = hex32(z);
    // print('@$i: 16($x, $xx) | $y, $yy) 32($z, $zz)');
  }
}
*/

  @override
  String toString() => '$runtimeType: rds: $rds, cds: $cds';

  Null shortFileError() {
    final s = 'Short file error: length(${rb.lengthInBytes}) $path';
    rb.warn('$s ${rb.rrr}');
    if (throwOnError) throw new ShortFileError('Length($rb.lengthInBytes) $path');
    return null;
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isNormalVR(int vrIndex) =>
    vrIndex >= kVRNormalIndexMin && vrIndex <= kVRNormalIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

final String kItemAsString = hex32(kItem32BitLE);
