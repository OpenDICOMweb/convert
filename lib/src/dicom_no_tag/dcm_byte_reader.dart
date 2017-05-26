// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:convertX/src/dcm_reader_base.dart';
import 'package:convertX/src/exception.dart';

const int kDataSetTrailingPadding = 0xFFFCFFFC;

//TODO: rewrite all comments to reflect current state of code
//  1. Move all [String] trimming and validation to the Element.  The reader
//     and writer should write the values as given.
//  2. Add a mode that will read with/without [String]s padded to an even length
//  3. Add a mode that will write with/without [String]s padded to an even length
//  4. Need a mode where read followed by write will produce two byte for byte identical
//     byte streams.
//  5. optimize by turning all internal method to private '_'.
//  6. when fully debugged and performance improvements done. cleanup and document.

/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
//typedef Element<E> VFReader<E>(int tag, VR<E> vr, int vfLength);

/*
                    kItem: 0xfffee000 4294893568
kSequenceDelimitationItem: 0xfffee0dd 4294893789
    kItemDelimitationItem: 0xfffee00d 4294893581
         kUndefinedLength: 0xffffffff 4294967295
 */
/// A library for parsing [Uint8List] containing DICOM File Format [ByteDataset]s.
///
/// Supports parsing LITTLE ENDIAN format in the super class [ByteBuf].
/// _Notes_:
///   1. In all cases DcmReader reads and returns the Value Fields as they
///   are in the data, for example DcmReader does not trim whitespace from
///   strings.  This is so they can be written out byte for byte as they were
///   read. and a byte-wise comparator will find them to be equal.
///   2. All String manipulation should be handled in the attribute itself.
///   3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
class DcmByteReader extends DcmReaderBase {
  static final Logger _log = new Logger("DcmReader", watermark: Severity
      .debug2);
  final RootByteDataset rootDS;

  bool _prefixRead = false;
  bool _fmiRead = false;

  //TODO: Doc
  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  DcmByteReader(ByteData bd,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingPrefix = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS})
      : rootDS = new RootByteDataset.fromByteData(bd,
            path: path, hadUndefinedLength: true),
        super(bd,
            path: path,
            throwOnError: throwOnError,
            allowILEVR: allowILEVR,
            allowMissingPrefix: allowMissingPrefix,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS) {
    currentDS = rootDS;
  }

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  factory DcmByteReader.fromBytes(Uint8List bytes,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    var bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    return new DcmByteReader(bd, path: path, targetTS: targetTS);
  }

  /// Reads a [RootByteDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootByteDataset readRootDataset({bool allowMissingFMI = false}) {
    _log.debug1('$rbb readRootDataset: endOfBD($endOfBD)');
    _fmiRead = readFMI();
    if (!_fmiRead && !allowMissingFMI && !rootDS.hasFMI) return null;
    _readDataset(rootDS, endOfBD);
    _log.debug1('$ree readRootDataset: ${rootDS.info}');
    return rootDS;
  }

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [ByteElement]s were present; otherwise, returns null.
  bool readFMI() {
    _log.debug2('$rbb readFmi($currentDS)');
    if (_fmiRead == true) throw 'DICOM Prefix has already been read';
    _readPrefix();
    try {
      //      _readDataset(rootDS, endOfBD, 0x00080000);
      while (rIndex < endOfBD) {
        int code = peekTagCode();
        if (code >= 0x00080000) break;
        EVRElement e = _readEVR();
        _log.debug('$rmm ${e.info}');
        currentDS.add(e);
      }
    } on InvalidTransferSyntaxError catch (x) {
      rootDS.hadParsingErrors = true;
      _log.warn('$ree readFMI TS catch: $x');
      //rethrow;
      rIndex = 0;
      return false;
    } catch (x) {
      rootDS.hadParsingErrors = true;
      _log.warn('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      rIndex = 0;
      rethrow;
    }

    TransferSyntax ts = rootDS.transferSyntax;
    _log.debug('$rmm readFMI: targetTS($targetTS), TS($ts) isExplicitVR: '
        '${rootDS.isExplicitVR}');
    //Urgent: collapse to one if statement
    if (ts == TransferSyntax.kExplicitVRBigEndian) {
      hadParsingErrors = true;
      if (throwOnError)
        throw new InvalidTransferSyntaxError(
            ts, 'Explicit VR Big Endian not supported.');
      rIndex = 0;
      return false;
    } else if (!rootDS.hasValidTransferSyntax) {
      hadParsingErrors = true;
      if (throwOnError)
        throw new InvalidTransferSyntaxError(ts, 'Not supported.');
      rIndex = 0;
      return false;
    } else if (targetTS != null && ts != targetTS) {
      if (throwOnError)
        throw new InvalidTransferSyntaxError(ts, 'Non-Target TS', ts);
      rIndex = 0;
      return false;
    }
    _log.debug2('$ree readFmi:\n ${rootDS.info}');
    return true;
  }

  bool _readPrefix() {
    if (rIndex != 0) throw 'Attempt to read DICOM Prefix at ByteData[$rIndex]';
    if (_prefixRead == true)
      throw 'Attempt to re-read DICOM Preamble and Prefix.';
    skip(128);
    final String prefix = readAsciiString(4);
    bool v = (prefix == "DICM") ? true : false;
    if (v == true) {
      rootDS.prefix = bd.buffer.asUint8List(0, 132);
      for (int i = 0; i < 128; i++) {
        if (bd.getUint8(i) != 0) {
          log.warn('**** Reading non-zero DICOM Prefix: '
              '  File: "$path"'
              '  Prefix: ${rootDS.prefix}');
          break;
        }
      }
    } else {
      if (throwOnError) {
        throw 'No DICOM Prefix present';
      } else {
        skip(-132);
      }
    }
    return v;
  }

  void _readDataset(ByteDataset ds, int endOfDS) {
    assert(currentDS != null);
    _log.debugDown('$rbb readDataset: isExplicitVR(${ds.isExplicitVR} endOfDS'
        '($endOfDS)');
    try {
      if (ds.isExplicitVR) {
        while (rIndex < endOfDS) currentDS.add(_readEVR());
      } else {
        while (rIndex < endOfDS) currentDS.add(_readIVR());
      }
    } catch (e) {
      _log.debug('$rmm _readDataset Caught $e');
      _atEndOfBD(endOfDS);
      rethrow;
    }
    _log.debugUp('$ree end readDataset: isExplicitVR(${ds.isExplicitVR})');
  }

  void _atEndOfBD(int endOfDS) {
    if (endOfDS != readIndex)
      _log.error('Not EOF: readIndex($rIndex), endOfDS($endOfDS), '
          'endOfBD(${bytes.lengthInBytes})');
    return;
  }

  // bool beyondPixelData = false;
  ByteElement _readEVR() {
    int start = rIndex;
    int code = readTagCode();
    int vrCode = readUint16();
    if (vrCode == kSQCode) {
      skip(2);
      return _readSequence(code, start, true);
    }
    VR vr = VR.lookup(vrCode);
    assert(vr != null, 'Invalid null VR: vrCode(${toHex16(vrCode)})');
    _log.debug1('$rbb _readEVR: start($start), ${toDcm(code)} $vr');
    int endOfVF;
    if (vr.hasShortVF) {
      int vfLength = 8 + readUint16();
      endOfVF = start + vfLength;
      rIndex = endOfVF;
    } else {
      skip(2);
      int vfLength = readUint32();
      if (code == kPixelData) return _readPixelData(true, vfLength);

      if (vfLength == kUndefinedLength) {
        endOfVF = _findEndOfVF(vfLength);
        rIndex = endOfVF + 8;
      } else {
        endOfVF = start + 12 + vfLength;
        rIndex = endOfVF;
        // Note: Not currently checking if encapsulated PixelData
        if (code == kPixelData) _checkPixelData(endOfVF);
      }
    }
    _log.debug2('$rmm _readIVR: endOfVF($endOfVF)');
    //Urgent: this will become the external interface
    var e = new EVRElement(_getElementBD(start, endOfVF));
    if (_afterPixelData == true) log.warn('After PixelData: ${e.info}');
    _log.debug1('$ree _readEVR: ${e.info}');
    return e;
  }

  bool _afterPixelData = false;

  /// Checks if data ends at the end of the PixelData Value Field.
  _checkPixelData(int endOfVF) {
    _afterPixelData = true;
    if (rIndex < bd.lengthInBytes) {
      log.warn('**** Data after PixelData Element:'
          'endOfVF($endOfVF), endOfBD($endOfBD)');
    }
  }

  ByteElement _readIVR() {
    bool isSequence() {
      int code = peekTagCode();
      if (code == kItem || code == kSequenceDelimitationItem) {
        skip(-4);
        return true;
      }
      return false;
    }

    int start = rIndex;
    int code = readTagCode();
    int vfLength = readUint32();
    _log.debug1('$rbb _readIVR: start($start), ${toDcm(code)} '
        'vfLength($vfLength, ${toHex32(vfLength)}');
    if (isSequence()) return _readSequence(code, start, false);
    if (code == kPixelData) return _readPixelData(true, vfLength);
    int endOfVF;
    if (vfLength == kUndefinedLength) {
      endOfVF = _findEndOfVF(vfLength);
      rIndex = endOfVF + 8;
    } else {
      endOfVF = start + 8 + vfLength;
      rIndex = endOfVF;
      // Note: Not currently checking if encapsulated PixelData
      if (code == kPixelData) _checkPixelData(endOfVF);
    }
    _log.debug2('$rmm _readIVR: endOfVF($endOfVF)');
    //Urgent: this will become the external interface
    var e = new IVRElement(_getElementBD(start, endOfVF));
    if (_afterPixelData == true) log.warn('After PixelData: ${e.info}');
    _log.debug1('$ree _readIVR: $e');
    return e;
  }

  ByteData _getElementBD(int start, int endOfVF) => (endOfVF > endOfBD)
      ? throw 'endOfVF($endOfVF) Beyond end of ByteData(${bd.lengthInBytes})'
      : bd.buffer.asByteData(start, endOfVF - start);

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads an EVR or IVR Sequence. The _readElementMethod detects Sequences.
  ByteElement _readSequence(int code, int start, bool isEVR) {
    int vfLength = readUint32();
    int vfStart = rIndex;
    var hadUndefinedLength = (vfLength == kUndefinedLength);
    _log.debugDown('$rbb SQ${toDcm(code)} start($start) undefinedLength'
        '($hadUndefinedLength), vfLength(${toHex32(vfLength)}, $vfLength)');
    int endOfVF;
    List<ByteItem> items = <ByteItem>[];
    if (hadUndefinedLength) {
//      _log.debug1('$rmm SQ${toDcm(code)} Undefined Length');
      while (!_checkForSequenceDelimiter()) {
        items.add(_readItem(isEVR));
      }
      endOfVF = rIndex;
      _log.debug2('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
      endOfVF = vfStart + vfLength;
      _log.debug2('$rmm SQ: ${toDcm(code)} vfLength($vfLength), '
          'endOfVF($endOfVF');
      while (rIndex < endOfVF) items.add(_readItem(isEVR));
      _log.debug2('$rmm SQ Length($vfLength) start($start) endOfVF($endOfVF)');
    }
    assert(rIndex == endOfVF);
    var bdx = _getElementBD(start, endOfVF);
    ByteSQ sq;
    //TODO: should be able to fix the type issue
    if (isEVR) {
      sq = new EVRSequence(bdx, currentDS, items, hadUndefinedLength);
    } else {
      sq = new IVRSequence(bdx, currentDS, items, hadUndefinedLength);
    }
    for (ByteItem item in items) item.addSQ(sq);
    _log.debugUp('$ree $sq');
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [ByteItem] or Fragment.
  ByteItem _readItem(bool isExplicitVR) {
    int code = readTagCode();
    int vfLength = readUint32();
    int start = rIndex; // start of elements
    _log.debug('$rbb item kItem(${toHex32(kItem)}, code ${toHex32(code)} '
        'vfLength($vfLength, ${toHex32(vfLength)}');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');

//    _log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    ByteDataset parentDS = currentDS;
    Map<int, ByteElement> elements = <int, ByteElement>{};
    bool hadUndefinedLength = vfLength == kUndefinedLength;
//    _log.debug1('$rmm readItem hadUndefinedLength=$hadUndefinedLength');
    int endOfVF;
    try {
      if (hadUndefinedLength) {
        while (!_checkForItemDelimiter()) {
          ByteElement e = _readElement(isExplicitVR);
          elements[e.code] = e;
        }
        endOfVF = rIndex;
      } else {
        endOfVF = start + vfLength;
        while (rIndex < endOfVF) {
          ByteElement e = _readElement(isExplicitVR);
          elements[e.code] = e;
        }
      }
    } on EndOfDataException {
      _log.error('$ree _readItem end of data exception: @$rIndex');
      rethrow;
    } catch (e) {
      hadParsingErrors = true;
      _log.error(e);
      rethrow;
    } finally {
      // Restore previous parent
      currentDS = parentDS;
    }

    ByteData bdx = _getElementBD(start, endOfVF);
    var item = new ByteItem.fromByteData(bdx, parentDS, elements, vfLength);
    _log.debug('$ree readItemElements: ${item.length} Items');
    return item;
  }

  ByteElement _readPixelData(isEVR, int vfLength) {
    log.debug('$rbb _readPixelData: isEVR($isEVR), vfLength($vfLength)');
    int startOfVF = rIndex;
    int endOfVF;
    List<Uint8List> fragments;
    if (vfLength == kUndefinedLength) {
      fragments = _readFragments();
      endOfVF = rIndex;
    } else {
      int endOfVF = startOfVF + vfLength;
      rIndex = endOfVF;
    }
    int startOfElement = startOfVF - ((isEVR) ? 12 : 8);
    var bdx = _getElementBD(startOfElement, endOfVF);
    ByteElement r = rootDS[PTag.kRows.code];
    int rows = r.uint16;
    int columns = rootDS[PTag.kColumns.code].uint16;
/*    return (isEVR)
        ? new EVRPixelData(bdx, rows, columns, fragments)

        : new IVRPixelData(bdx, rows, columns, fragments);
*/
    ByteElement e = (isEVR)
        ? new EVRPixelData(bdx, rows, columns, fragments)
        : new IVRPixelData(bdx, rows, columns, fragments);
    log.debug('$ree _readPixelData: ${e.info}');
    return e;
  }

// TODO: move into Pixel Data
// & readElementExplicit
  /// Returns an [ByteItem] or Fragment.
  List<Uint8List> _readFragments() {
    var fragments = <Uint8List>[];
    int code = readTagCode();
    do {
      assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
      int vfLength = readUint32();
      assert(
          vfLength != kUndefinedLength,
          'Invalid length: ${toDcm(
          vfLength)}');
      int start = rIndex;
      rIndex += vfLength;
      fragments.add(bd.buffer.asUint8List(start, rIndex - start));
      code = readTagCode();
    } while (code != kSequenceDelimitationItem);
    code = readTagCode();
    if (code != 0)
      log.warn('Pixel Data Sequence delimiter has non-zero '
          'value: $code/0x${toHex32(code)}');
    return fragments;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  bool _checkForSequenceDelimiter() {
//    _log.debug('$rmm check SQ Delimiter');
    return _checkForDelimiter(kSequenceDelimitationItem);
  }

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  bool _checkForItemDelimiter() {
    _log.debug2('$rmm check Item Delimiter');
    return _checkForDelimiter(kItemDelimitationItem);
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced past the Value Length Field;
  /// otherwise, readIndex does not change
  bool _checkForDelimiter(int target) {
    int delimiter = peekTagCode();
//    _log.debug2('$rmm delimiter(${toHex32(delimiter)}), '
    //       'target(${toHex32(target)})');
    if (delimiter == target) {
      skip(4);
      int delimiterLength = readUint32();
      if (delimiterLength != 0) _delimiterLengthFieldWarning(delimiterLength);
      return true;
    }
    return false;
  }

  void _delimiterLengthFieldWarning(int dLength) {
    rootDS.hadNonZeroDelimiterLength = true;
    _log.warn('$rmm: Encountered a delimiter with a non zero length($dLength)'
        ' field');
  }

  /// Reads the Value Field until the [kSequenceDelimiter] is found.
  int _findEndOfVF(int vfLength) {
    if (vfLength == kUndefinedLength) {
      while (isReadable) {
        if (readUint16() != kDelimiterFirst16Bits) continue;
        if (readUint16() != kSequenceDelimiterLast16Bits) continue;
        break;
      }
      int delimiterLength = readUint32();
      if (delimiterLength != 0) _delimiterLengthFieldWarning(delimiterLength);
      int endOfVF = rIndex - 8;
      return endOfVF;
    }
    hadParsingErrors = true;
    throw "vfLength($vfLength) not kUndefinedLength";
  }

  // Enhancement
//  int _readPrivateGroup(int group) { return 2; }

// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (!readFMI() || !rootDS.hasFMI || !rootDS.hasValidTransferSyntax)
      return null;
    return rootDS.transferSyntax;
  }

  ByteElement _readElement(bool isExplicitVR) =>
      (isExplicitVR) ? _readEVR() : _readIVR();

  ByteElement xReadPublicElement([bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  ByteElement xReadPGLength([bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  ByteElement xReadPrivateIllegal(int code, [bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  ByteElement xReadPrivateCreator([bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  ByteElement xReadPrivateData(ByteElement pc, [bool isExplicitVR = true]) {
    //  _TagMaker maker =
    //      (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
    return _readElement(isExplicitVR);
  }

  // Reads
  ByteDataset xReadDataset([bool isExplicitVR = true]) {
    _log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    while (isReadable) {
      var e = _readElement(isExplicitVR);
      rootDS.add(e);
      e = rootDS[e.code];
      assert(e == e);
    }
    _log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    return currentDS;
  }

/*
  static RootByteDataset rootDataset(Uint8List bytes,
      {String path = "",
        TransferSyntax targetTS,
        bool fmiOnly = false,
        fast = false}) {
    if (path.length > 0) _log.info('Reading: $path');
    DcmByteReader reader =
    new DcmByteReader.fromBytes(bytes, path: path, targetTS: targetTS);
    if (fmiOnly) {
      var ok = reader.readFMI();
      return (ok) ? reader.rootDS : null;
    }
    var rds = reader.readRootDataset();
    _log.info('${reader.info}');
    return rds;
  }
*/

  static RootByteDataset readBytes(Uint8List bytes,
      {String path: "",
      bool fmiOnly = false,
      fast = true,
      TransferSyntax targetTS}) {
    if (bytes == null) throw new ArgumentError('readBytes: $bytes');
    if (bytes.length < 256) {
      log.error('**** DcmReader: Too few bytes: ${bytes.length} in $path');
      return null;
    }
    DcmByteReader reader =
        new DcmByteReader.fromBytes(bytes, path: path, targetTS: targetTS);
    if (fmiOnly) {
      var ok = reader.readFMI();
      return (ok) ? reader.rootDS : null;
    }
    var rds = reader.readRootDataset();
    _log.info('${reader.info}');
    return rds;
  }

  static RootByteDataset readFile(File file,
      {bool fmiOnly = false, bool fast: false, TransferSyntax targetTS}) {
    if (file == null) throw new ArgumentError('readFile: $file');
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  static RootByteDataset readPath(String path,
          {bool fmiOnly = false, bool fast = false, TransferSyntax targetTS}) =>
      readFile(new File(path),
          fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);

  static ByteDataset read(from,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    if (from is String)
      return readPath(from, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (from is File)
      return readFile(from, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (from is Uint8List)
      return readBytes(from,
          path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    throw new ArgumentError('$from');
  }

  static Instance readInstance(obj,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    var rds =
        read(obj, path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    return new Instance.fromDataset(rds);
  }
}
