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
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/binary/base/reader/base/reader_base.dart';

//part 'package:dcm_convert/src/binary/base/reader/read_utils.dart';

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
abstract class DbgReaderBase extends DcmReaderBase {
  final ParseInfo pInfo;
  final ElementOffsets offsets;
  int elementCount = -1;
  bool beyondPixelData = false;

  /// The [ByteData] being read.
  // final int bdLength;

  /// Creates a new [DcmReaderBase]  where [rb].rIndex = 0.
  DbgReaderBase(ByteData bd, RootDataset rds,
      {String path = '',
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super(bd, rds, path: path, reUseBD: reUseBD, dParams: dParams) {
    log.debug('''Creating $this
  File: '$path'
''');
  }

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  @override
  RootDataset read() {
    if (pInfo.wasShortFile) return shortFileError();
    return super.read();
  }

  @override
  bool readFmi(RootDataset rds) {
    log.debug('${rb.rbb} reading FMI');
    super.readFmi(rds);
  }

  @override
  Element readDefinedLength(
          int code, int eStart, int vrIndex, int vlf, EBMaker ebMaker) =>
      __readDefinedLength(code, eStart, vrIndex, vlf, ebMaker);

  Element readMaybeUndefinedLength(
          int code, int eStart, int vrIndex, int vlf, EBMaker ebMaker, EReader eReader) =>
      __readMaybeUndefinedLength(code, eStart, vrIndex, vlf, ebMaker, eReader);

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

  bool _inItem;

  void readRootDataset(EReader eReader) {
    log
      ..reset
      ..debug('${rb.rbb} readRootDataset');

    super.readRootDataset(eReader);

    log.debug('${rb.ree} readRootDataset $elementCount Elements read with '
        '${rb.remaining} bytes remaining\nDatasets: ${pInfo.nDatasets}');
  }

  /// Returns an [Item].
  // rIndex is @ delimiterFvr
  Item readItem(EReader eReader, int count) {
    //startReadDS(Item, count, vfLengthField);
    final item = super.readItem(eReader, count);
    // readItemStart('Reading Item', count , vfLengthField', 1);
    log.debug('${rb.ree} End Reading item #$count', -1);
    return item;
  }

  void readDatasetDefinedLength(Dataset ds, int dsStart, int vfLength, EReader eReader) {
    final dsEnd = dsStart + vfLength;
    log.debug2('${rb.rbb} readDatasetDefined $dsStart - $dsEnd: $vfLength', 1);

    super.readDatasetDefinedLength(ds, dsStart, vfLength, eReader);

    log.debug2('${rb.ree} readDatasetDefined $elementCount Elements read', -1);
    pInfo.nDefinedLengthDatasets++;
  }

  void readDatasetUndefinedLength(Dataset ds, EReader eReader) {
    log.debug2('${rb.rbb} readEvrDatasetUndefined', 1);

    super.readDatasetUndefinedLength(ds, eReader);

    log.debug2('${rb.ree} readDatasetUndefined $elementCount Elements read', -1);
    pInfo.nUndefinedLengthDatasets++;
  }

  int _sqDepth = 0;
  bool get _inSQ => _sqDepth <= 0;

  /// Read a Sequence.
  Element readSQ(int code, int eStart, int vlf, EBMaker ebMaker, EReader eReader) {
    final eNumber = elementCount;
    log.debug('${rb.rbb} #$eNumber readSQ ${dcm(code)} @$eStart vfl:$vlf', 1);
    _sqDepth++;
    pInfo.nSequences++;

    super.readSQ(code, eStart, vlf, ebMaker, eReader);
    (vlf == kUndefinedLength)
        ? pInfo.nUndefinedLengthSequences++
        : pInfo.nDefinedLengthSequences++;
    ;
    _sqDepth--;
    if (_sqDepth < 0) readError('_sqDepth($_sqDepth) < 0');
    log.debug('${rb.ree} #$eNumber readSQ ${dcm(code)} $e', -1);
    return e;
  }

  /// Reads a [kUndefinedLength] Sequence.
  Element _readUSQ(int code, int eStart, int uLength, EBMaker ebMaker, EReader eReader) {
    assert(uLength == kUndefinedLength);
    final items = <Item>[];
    pInfo.nUndefinedLengthSequences++;

    // print('_element #$elementCount');
    // print('offsets: ${offsets.length}');
    final offsetIndex = offsets.reserveSlot;
    log.debug('${rb.rbb} readUSQ Reading ${items.length} Items', 1);
    var itemCount = 0;
    while (!__isSequenceDelimiter()) {
      final item = readItem(eReader, itemCount);
      items.add(item);
      itemCount++;
    }
    log.debug('${rb.ree} USQ Read $itemCount Items', -1);
    final e = _makeSequence(code, eStart, ebMaker, items);
    // print('*** insert at $offsetIndex $eStart ${e.eStart} ${e.eEnd}');
    offsets.insertAt(offsetIndex, e.eStart, e.eEnd, e);
    return e;
  }

  /// Reads a defined [vfLength].
  Element _readDSQ(int code, int eStart, int vfLength, EBMaker ebMaker, EReader eReader) {
    assert(vfLength != kUndefinedLength);
    final items = <Item>[];
    pInfo.nDefinedLengthSequences++;

    final vfStart = rb.rIndex;
    // print('eStart: $eStart, vfStart: $vfStart, vfLength: $vfLength');
    //  assert(eStart == rb.rIndex - 12, '$eStart == ${rb.rIndex - 12}');
    // print('_element #$elementCount');
    // print('offsets: ${offsets.length}');
    final offsetIndex = offsets.reserveSlot;
    log.debug2('${rb.rbb} readDSQ Reading ${items.length} Items', 1);
    final eEnd = vfStart + vfLength;
    var itemCount = 0;
    while (rb.rIndex < eEnd) {
      final item = readItem(eReader, itemCount);
      items.add(item);
      itemCount++;
    }
    final end = rb.rIndex;
    assert(eEnd == end, '$eEnd == $end');
    log.debug2('${rb.ree} DSQ Read $itemCount Items', -1);
    final e = _makeSequence(code, eStart, ebMaker, items);
    // print('insert at $offsetIndex');
    // print('*** insert at $offsetIndex $eStart ${rb.rIndex} ${e.eStart} ${e.eEnd}');
    offsets.insertAt(offsetIndex, eStart, eEnd, e);
    return e;
  }

  // If VR is UN then this might be a Sequence
  Element __tryReadUNSequence(
      int code, int eStart, int vlf, EBMaker ebMaker, EReader eReader) {
    log.debug3('${rb.rmm} *** Maybe Reading Evr UN Sequence');
    final delimiter = rb.getUint32(rb.rIndex);
    if (delimiter == kSequenceDelimitationItem32BitLE) {
      // An empty Sequence
      pInfo.nSequences++;
      pInfo.nEmptyUNSequences++;
      log.debug3('${rb.rmm} *** Empty Evr UN Sequence');
      _readAndCheckDelimiterLength();
      return _makeSequence(code, eStart, EvrLong.make, emptyItemList);
    } else if (delimiter == kItem) {
      // A non-empty Sequence
      log.debug3('${rb.rmm} *** Found UN Sequence');
      _readAndCheckDelimiterLength();
      pInfo.nSequences++;
      pInfo.nNonEmptyUNSequences++;
      return __readSQ(code, eStart, vlf, EvrLong.make, eReader);
    }
    log.debug3('${rb.rmm} *** UN Sequence not found');
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
      pInfo.nonZeroDelimiterLengths++;
      rb.warn('Encountered non-zero delimiter length($length) ${rb.rrr}');
    }
  }

  /// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
  /// kUndefinedValue.
  Element __readMaybeUndefinedLength(int code, int eStart, int vrIndex, int vlf,
      EBytes ebMaker(ByteData bd), EReader eReader) {
    log.debug(
        '${rb.rbb} readMaybeUndefined ${dcm(code)} vr($vrIndex) '
        '$eStart + 12 + ??? = ???',
        1);
    // If VR is UN then this might be a Sequence
    if (vrIndex == kUNIndex) {
      final e = __tryReadUNSequence(code, eStart, vlf, ebMaker, eReader);
      if (e != null) return e;
    }
    pInfo.nMaybeUndefinedElements++;
    return (vlf == kUndefinedLength)
        ? __readUndefinedLength(code, eStart, vrIndex, vlf, ebMaker)
        : __readDefinedLength(code, eStart, vrIndex, vlf, ebMaker);
  }

  // Finish reading an EVR Long Defined Length Element
  Element __readDefinedLength(
      int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
    assert(vlf != kUndefinedLength);

    log.debug('${rb.rmm} readLongDefinedLength ${dcm(code)} vr($vrIndex) '
        '$eStart + 12 + $vlf = ${eStart + 12 + vlf}');
    pInfo.nLongDefinedLengthElements++;
    rb + vlf;
    return (code == kPixelData)
        ? _makePixelData(code, eStart, vrIndex, rb.rIndex, false, ebMaker)
        : makeElement(code, eStart, vrIndex, rb.rIndex, ebMaker);
  }

  // Finish reading an EVR Long Undefined Length Element
  Element __readUndefinedLength(
      int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
    assert(vlf == kUndefinedLength);
    log.debug('${rb.rmm} readEvrUndefinedLength ${dcm(code)} vr($vrIndex) '
        '$eStart + 12 + ??? = ???');
    pInfo.nUndefinedLengthElements++;
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
    assert(isMaybeUndefinedLengthVR(vrIndex));
    log.debug1('${rb.rbb} readEncapsulatedPixelData', 1);

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
    assert(isMaybeUndefinedLengthVR(vrIndex));
    __checkForOB(vrIndex, rds.transferSyntax);

    final fragments = __readFragments();
    log.debug3('${rb.ree}  read Fragments: $fragments', -1);
    return _makePixelData(code, eStart, vrIndex, rb.rIndex, true, ebMaker, fragments);
  }

  void __checkForOB(int vrIndex, TransferSyntax ts) {
    if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
      final vr = VR.lookupByIndex(vrIndex);
      rb.warn('Invalid VR($vr) for Encapsulated TS: $ts ${rb.rrr}');
      pInfo.hadParsingErrors = true;
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
      log.debug3('${rb.rbb} readFragment ${dcm(delimiter)} length: $vlf', 1);
      assert(vlf != kUndefinedLength, 'Invalid length: ${dcm(vlf)}');

      final startOfVF = rb.rIndex;
      final endOfVF = rb + vlf;
      fragments.add(rb.buffer.asUint8List(startOfVF, endOfVF - startOfVF));

      log.debug3('${rb.ree}  length: ${endOfVF - startOfVF}', -1);
      delimiter = rb.uint32;
    } while (delimiter != kSequenceDelimitationItem32BitLE);

    _checkDelimiterLength(delimiter);

    pInfo.pixelDataHadFragments = true;
    final v = new VFFragments(fragments);
    return v;
  }

  void _checkDelimiterLength(int delimiter) {
    final vfLengthField = rb.uint32;
    if (vfLengthField != 0)
      rb.warn('Delimiter has non-zero '
          'value: $delimiter/0x${hex32(delimiter)} ${rb.rrr}');
  }

  void doEndOfElementStats(int code, int eStart, Element e, bool ok) {
    pInfo.nElements++;
    if (ok) {
      pInfo.lastElementRead = e;
      pInfo.endOfLastElement = rb.rIndex;
      if (e.isPrivate) pInfo.nPrivateElements++;
      if (e is SQ) {
        pInfo.endOfLastSequence = rb.rIndex;
        pInfo.lastSequenceRead = e;
      }
    } else {
      pInfo.nDuplicateElements++;
    }
    if (e is! SQ) offsets.add(eStart, rb.rIndex, e);
  }

  // vfLength cannot be undefined.
  Element makeElement(
      int code, int eStart, int vrIndex, int endOfVF, EBytes ebMaker(ByteData bd)) {
    assert(endOfVF != kUndefinedLength);
    final eb = _makeEBytes(eStart, ebMaker);
    return eMaker(eb, vrIndex);
  }

  PixelData _makePixelData(int code, int eStart, int vrIndex, int endOfVF, bool undefined,
      EBytes ebMaker(ByteData bd),
      [VFFragments fragments]) {
    beyondPixelData = true;
    doPixelDataStats(eStart, endOfVF, vrIndex, undefined);
    final eb = _makeEBytes(eStart, ebMaker);
    log.debug3('${rb.ree} _makePixelData: $eb');
    beyondPixelData = true;
    return pixelDataMaker(eb, vrIndex, rds.transferSyntax, fragments);
  }

  EBytes _makeEBytes(int eStart, EBytes ebMaker(ByteData bd)) =>
      ebMaker(rb.buffer.asByteData(eStart, rb.rIndex - eStart));

  void doPixelDataStats(int eStart, int endOfVF, int vrIndex, bool undefined) {
    final eLength = endOfVF - eStart;
    pInfo
      ..pixelDataStart = eStart
      ..pixelDataLength = eLength
      ..pixelDataHadUndefinedLength = undefined
      ..pixelDataVR = VR.lookupByIndex(vrIndex);
  }

  @override
  Tag checkCode(int code, int eStart) {
    if (code < 0x00020000 || code >= kItem) {
      if (beyondPixelData) {
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
    if (code > 0x3000 && (elt == 0)) pInfo.hadGroupLengths = true;

    final tag = Tag.lookup(code);
    if (tag == null) {
      rb.warn('Tag is Null: ${dcm(code)} start: $eStart ${rb.rrr}');
      showNext(rb.rIndex - 4);
    }
    return tag;
  }

  /// Returns true if there are only trailing zeros at the end of the
  /// Object being parsed.
  Null _zeroEncountered(int code) {
    final msg = (beyondPixelData) ? 'after kPixelData' : 'before kPixelData';
    rb.warn('Zero encountered $msg ${rb.rrr}');
    throw new EndOfDataError('Zero encountered $msg ${rb.rrr}');
  }

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

  //Urgent move to evr_dbg_reader and ivr_dbg_reader.
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
