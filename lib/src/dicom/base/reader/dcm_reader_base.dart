// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/read_buffer.dart';
import 'package:convert/src/errors.dart';

// ignore_for_file: avoid_positional_boolean_parameters

// Reader axioms
// 1. The read index (rIndex) should always be at the last place read,
//    and the end of the value field should be calculated by subtracting
//    the length of the delimiter and delimiter length field, which is 8 bytes.
//
// 2. For non-sequence Elements with undefined length (kUndefinedLength)
//    the read index rIndex is left at the end of the Element Delimiter.

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
abstract class DcmReaderBase<V> {

  // **** Interface ****
  /// The [ReadBuffer] being read.
  ReadBuffer get rb;

  /// The [RootDataset].
  RootDataset get rds;

  /// The current Dataset.
  Dataset get cds;
  set cds(Dataset ds);

  /// Returns a new [Element].
  Element makeFromByteData(int code, int vrIndex, ByteData bd);

  /// Returns a new [Element].
//  Element makeFromValues(int code, int vrIndex, ByteData bd);

  /// Returns a new Pixel Data [Element].
  Element makePixelData(int code, int vrIndex, ByteData bd,
      [TransferSyntax ts, VFFragments fragments]);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequence(int code, ByteData bd, Dataset cds, List<Item> items);

  /// Returns a new [RootDataset].
//  RootDataset makeRootDataset({ByteData bd, ElementList elements, String path});

  /// Returns a new [Item].
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence});

  void readFmi();

  Element readElement();

  Element readSequence(int code, int eStart, int vrIndex);

  // **** End of interface ****

  /// The current [Element] [Map].
  List<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  List<Element> get duplicates => cds.elements.duplicates;

  bool get isReadable => rb.isReadable;

  Uint8List get rootBytes => rb.buffer.asUint8List(rb.offsetInBytes, rb.lengthInBytes);

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  bool hasRemaining(int n) => rb.hasRemaining(n);

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
    print('** readRootDataset: ${rb.rIndex} : ${rb.rRemaining}');
    readDatasetDefinedLength(rds, rdsStart, rb.rRemaining);
    final rdsLength = rb.rIndex - rdsStart;
    print('** readRootDataset: rdsLength = $rdsLength');
    final rbd = rb.bd.buffer.asByteData(rdsStart, rdsLength);
    rds.dsBytes = new RDSBytes(rbd, fmiEnd);
    return rds;
  }

  /// Returns an [Item].
  // rIndex is @ delimiterFvr
  Item readItem() {
    assert(rb.hasRemaining(8));
    final iStart = rb.rIndex;

    // read 32-bit kItem code and Item length field
    final delimiter = rb.getUint32(rb.rIndex);
    if (delimiter != kItem32BitLE) throw 'Missing Item Delimiter';
    rb.skip(4);
    final vfLengthField = rb.uint32;
    final item = makeItem(cds);
    final parentDS = cds;
    cds = item;

    (vfLengthField == kUndefinedLength)
        ? readDatasetUndefinedLength(item)
        : readDatasetDefinedLength(item, rb.rIndex, vfLengthField);

    cds = parentDS;
    final bd = rb.buffer.asByteData(iStart, rb.rIndex - iStart);
    item.dsBytes = new IDSBytes(bd);
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
      final e = readElement();
      final ok = ds.tryAdd(e);
      if (!ok) log.warn('*** duplicate: $e');
    }
  }

  void readDatasetUndefinedLength(Dataset ds) {
    while (!_isItemDelimiter()) {
      // Elements are always read into the current dataset.
      // **** This is the only place they are added to the dataset.
      final e = readElement();
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
    final length = rb.uint32;
    if (length != 0) log.warn('Encountered non-zero delimiter length($length)');
    final endOfVF = rb.rIndex - 8;
    return endOfVF;
  }

  /// If the sequence delimiter is found at the current _read index_, reads the
  /// _delimiter_, reads and checks the _delimiter length_ field, and returns _true_.
  bool isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  /// Returns true if the [target] delimiter is found. If the target
  /// delimiter is found the _read index_ is advanced to the end of the delimiter
  /// field (8 bytes); otherwise, readIndex does not change.
  bool _checkForDelimiter(int target) {
    final delimiter = rb.uint32Peek;
    if (target == delimiter) {
      rb.skip(4);
      final length = rb.uint32;
      if (length != 0) log.warn('Encountered non-zero delimiter length($length)');
      return true;
    }
    return false;
  }

  void _readAndCheckDelimiterLength() {
    final length = rb.uint32;
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
  VFFragments _readEncapsulatedPixelData(int code, int eStart, int vrIndex, int vlf) {
    assert(vlf == kUndefinedLength);
    assert(_isMaybeUndefinedLengthVR(vrIndex));

    final delimiter = rb.getUint32(rb.rIndex);
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
  VFFragments _readPixelDataFragments(int code, int eStart, int vrIndex, int vlf) {
    assert(_isMaybeUndefinedLengthVR(vrIndex));
    _checkForOB(vrIndex, rds.transferSyntax);
    return _readFragments();
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
  VFFragments _readFragments() {
    final fragments = <Uint8List>[];
    var delimiter = rb.uint32;
    do {
      assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
      final vlf = rb.uint32;
      print('fragment vlf: $vlf');
      assert(vlf != kUndefinedLength, 'Invalid length: ${dcm(vlf)}');

      final startOfVF = rb.rIndex;
      final endOfVF = rb.rSkip(vlf);
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
      log.warn('Delimiter has non-zero '
          'value: $delimiter/0x${hex32(delimiter)}');
  }

  Tag checkCode(int code, int eStart) {
    final tag = Tag.lookup(code);
    if (tag == null) {
      log.warn('Tag is Null: ${dcm(code)} start: $eStart');
// TODO: move to log/debug version
//      showNext(rb.rIndex - 4);
    }
    return tag;
  }

  bool isValidVR(int code, int vrIndex, Tag tag) => _isValidVR(code, vrIndex, tag);
  bool _isValidVR(int code, int vrIndex, Tag tag) {
    if (vrIndex == kUNIndex) return true;
    if (tag.hasNormalVR && vrIndex == tag.vrIndex) return true;
    if (tag.hasSpecialVR && isNormalVRIndex(vrIndex)) return true;
    if (tag is PDTagUnknown) return true;
    log.error('**** vrIndex $vrIndex is not valid for $tag');
    return false;
  }

  bool isNotValidVR(int code, int vrIndex, Tag tag) => !_isValidVR(code, vrIndex, tag);

  int correctVR(int code, int vrIndex, Tag tag) {
    if (vrIndex == kUNIndex) {
      if (tag.vrIndex == kUNIndex) return vrIndex;
      return (tag.hasNormalVR) ? tag.vrIndex : vrIndex;
    }
    return vrIndex;
  }

  /// Returns true if there are only trailing zeros at the end of the
  /// Object being parsed.
  Null zeroEncountered(int code) => throw new EndOfDataError('Zero encountered');

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
    if (throwOnError) throw new ShortFileError('Length($rb.lengthInBytes) $path');
    return null;
  }

  // **** Logging Interface ****
  void logStartRead(int code, int vrIndex, int eStart, int vlf, String name) {}

  void logEndRead(int eStart, Element e, String name, {bool ok}) {}

  void logStartSQRead(int code, int vrIndex, int eStart, int vlf, String name) {}

  void logEndSQRead(int eStart, Element e, String name, {bool ok = true}) {}
}

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

final String kItemAsString = hex32(kItem32BitLE);