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
//  3. Add a mode that will write with/without [String]s padded to an even
//     length
//  4. Need a mode where read followed by write will produce two byte for byte
//     identical byte streams.
//  5. optimize by turning all internal method to private '_'.
//  6. when fully debugged and performance improvements done. cleanup and
//     document.

/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
//typedef Element<E> VFReader<E>(int tag, VR<E> vr, int vfLength);

/*
                    kItem: 0xfffee000 4294893568
kSequenceDelimitationItem: 0xfffee0dd 4294893789
    kItemDelimitationItem: 0xfffee00d 4294893581
         kUndefinedLength: 0xffffffff 4294967295
 */
/// A library for parsing [Uint8List] containing DICOM File Format
/// [ByteDataset]s.
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
class DcmReader extends DcmReaderBase {
  static final Logger _log = new Logger("DcmReader", watermark: Severity.info);
  RootByteDataset rootDS;
  Dataset currentDS;

  //TODO: Doc
  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReader(ByteData bd, Map<int, dynamic> fmi,
      {Part10Header part10,
      String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingPrefix = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS})
      : super(bd, fmi,
            path: path,
            throwOnError: throwOnError,
            allowILEVR: allowILEVR,
            allowMissingPrefix: allowMissingPrefix,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS);

  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  factory DcmReader.fromBytes(Uint8List bytes, Map<int, dynamic> fmi,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    var bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    return new DcmReader(bd, fmi, path: path, targetTS: targetTS);
  }

  /// Reads a [RootByteDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootByteDataset readRootDataset({bool allowMissingFMI = false}) {
    _log.debug1('$rbb readRootDataset: endOfBD($endOfBD)');
    if (!hadFMI && !allowMissingFMI && !hadFMI) return null;
    currentDS = rootDS;
    _readDataset(currentDS, endOfBD);
    rootDS = currentDS;
    _log.debug1('$ree readRootDataset: ${rootDS.info}');
    return rootDS;
  }

/*  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [ByteElement]s were present; otherwise, returns null.
  Map<int, Element> readFMI() {
    _log.debug2('$rbb readFmi($currentDS)');
    if (rIndex != 0) throw 'DICOM Prefix has already been read';
    var prefix = DcmPrefix.readPrefix(bd);
    try {
      while (rIndex < endOfBD) {
        int code = peekTagCode();
        if (code >= 0x00030000) break;
        ByteElement e = _readEVR();
        currentDS.add(e);
      }
    } on InvalidTransferSyntaxError catch (x) {
      rootDS.hadParsingErrors = true;
      _log.warn('$ree readFMI Invalid TS catch: $x');
      if (throwOnError) rethrow;
    } catch (x) {
      rootDS.hadParsingErrors = true;
      _log.warn('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      if (throwOnError) rethrow;
    } finally {
      rIndex = 0;
      return {};
    }
  }*/

/*  Uint8List _readPrefix() {
    if (rIndex != 0) throw 'Attempt to read DICOM Prefix at ByteData[$rIndex]';
    if (_prefixRead == true)
      throw 'Attempt to re-read DICOM Preamble and Prefix.';
    final preable = read(128);

    final String prefix = readAsciiString(4);
    bool v = (prefix == "DICM") ? true : false;
    if (v == true) {
      Uint8List prefix = bd.buffer.asUint8List(0, 132);
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
    return prefix;
  }*/

  void _readDataset(ByteDataset ds, int endOfDS) {
    assert(currentDS != null);
    _log.debugDown('$rbb readDataset: isEVR(${ds.isEVR} endOfDS'
        '($endOfDS)');
    try {
      if (ds.isEVR) {
        while (rIndex < endOfDS) currentDS.add(_readEVR());
      } else {
        while (rIndex < endOfDS) currentDS.add(_readIVR());
      }
    } catch (e) {
      _log.debug('$rmm _readDataset Caught $e');
      assert(endOfDS == rIndex, 'endOfDS($endOfDS} != rIndex($rIndex)');
      rethrow;
    }
    assert(endOfDS == rIndex, 'endOfDS($endOfDS} != rIndex($rIndex)');
    _log.debugUp('$ree end readDataset: isEVR(${ds.isEVR})');
  }

/*
  bool _atEndOfBD(int endOfDS) {
    if (endOfDS != rIndex) {
      _log.error('Not EOF: readIndex($rIndex), endOfDS($endOfDS), '
          'endOfBD(${bd.lengthInBytes})');
      return false;
    }
    return true;
  }
*/

  ByteElement readElement([bool isEVR = true]) =>
      (isEVR) ? _readEVR() : _readIVR;

  // bool beyondPixelData = false;
  ByteElement _readEVR() {
    int start = rIndex;
    int code = readTagCode();
    int vrCode = readUint16();
    assert(rIndex == start + 6);
    VR vr = VR.lookup(vrCode);
    assert(vr != null, 'Invalid null VR: vrCode(${toHex16(vrCode)})');
    _log.debug1('$rbb ${toDcm(code)} $vr');
    if (vrCode == kSQCode) {
      skip(2);
      return _readSequence(code, start);
    }
    _log.debug1('$rmm     start($start) _readEVR: ');
    if (vr.hasShortVF) {
      int vfLength = readUint16();
      _log.debug1('$rmm     vfLength: $vfLength');
      assert(rIndex == start + 8);
      rIndex += vfLength;
    } else {
      skip(2);
      int vfLength = readUint32();
      _log.debug1('$rmm     vfLength: $vfLength');
      assert(rIndex == start + 12);
      if (code == kPixelData) {
        EVRPixelData e = _readPixelData(start, vfLength, true);
        _log.debug1('$ree     ${e.info} _readEVR: ');
        return e;
      }
      if (vfLength == kUndefinedLength) {
        // Undefined Length - must find delimiter.
        log.debug('$rmm: ${toDcm(code)} $vr with Undefined Length');
        _findEndOfVF(vfLength);
      } else {
        rIndex += vfLength;
      }
    }
    _log.debug2('$rmm     endOfVF($rIndex) _readEVR: ');
    //Enhancement: this will become the external interface
    var e = new EVRElement(_getElementBD(start, rIndex));
    //Urgent    assert(check(e));
    if (_afterPixelData == true) log.warn('After PixelData: ${e.info}');
    _log.debug1('$ree     $e');
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
    print('$rbb start: $start ');
    int code = readTagCode();
    print('$rmm code(${Tag.toDcm(code)}, $code) ');
    int vfLength = readUint32();
    print('$rmm vfLength($vfLength) ');
    _log.debug1('$rbb _readIVR: start($start), ${toDcm(code)} '
        'vfLength($vfLength, ${toHex32(vfLength)}');
    if (isSequence()) return _readSequence(code, start);
    if (code == kPixelData) {
      IVRPixelData e = _readPixelData(start, vfLength, false);
      _log.debug1('$ree _readEVR: ${e.info}');
      return e;
    }
    //   int endOfVF;
    if (vfLength == kUndefinedLength) {
      rIndex = _findEndOfVF(vfLength);
      //     rIndex = endOfVF + 8;
    } else {
      rIndex += vfLength;
      log.debug('$rmm vfLength($vfLength)');
      //    rIndex = endOfVF;
      // Note: Not currently checking if encapsulated PixelData
      if (code == kPixelData) _checkPixelData(rIndex);
    }
    _log.debug2('$rmm _readIVR: start($start) end($rIndex)');
    //Urgent: this will become the external interface
    var e = new IVRElement(_getElementBD(start, rIndex));
    if (_afterPixelData == true) log.warn('After PixelData: $e');
    print(e.runtimeType);
    print(e.dcm);
    print(e.vr);
    print(e.bd.offsetInBytes);
    print(e.bd.lengthInBytes);
    print(e.vfOffset);
    print(e.vfLength);
    print(toHex32(e.vfLength));
    print(e.vfBytes);
    print(e.vfBytes.length);
    print('e: $e');
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
  ByteElement _readSequence(int code, int start) {
    int xxx = rIndex;
    int vfLength = readUint32();
    if (vfLength.isOdd && vfLength != kUndefinedLength) {
      log.error('Value Field Length is odd integer: '
          '$vfLength, 0x${toHex32(vfLength)}');
      vfLength += 1;
    }
    int vfStart = rIndex;
    var isUndefined = (vfLength == kUndefinedLength);
    _log.debugDown('$rbb SQ${toDcm(code)} start($start) undefinedLength'
        '($isUndefined), vfLength(${toHex32(vfLength)}, $vfLength)');
    int endOfVF;
    List<ByteItem> items = <ByteItem>[];
    if (isUndefined) {
      while (!_checkForSequenceDelimiter()) {
        items.add(_readItem());
      }
      endOfVF = rIndex;
      _log.debug2('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
      endOfVF = vfStart + vfLength;
      _log.debug2('$rmm SQ: ${toDcm(code)} vfL($vfLength), EOVF($endOfVF)');
      while (rIndex < endOfVF) {
        items.add(_readItem());
        xxx = rIndex;
      }
      _log.debug2('$rmm SQ VFL($vfLength) start($start) EOVF($endOfVF)');
    }

    xxx = rIndex;
    //  assert(rIndex == endOfVF, "readSequence: rIndex($rIndex) != endOfVF"
    //      "($endOfVF)");
    var bdx = _getElementBD(start, rIndex);
    ByteSQ sq;
    //TODO: should be able to resolve the type
    if (rootDS.isEVR) {
      sq = new EVRSequence(bdx, currentDS, items, isUndefined);
    } else {
      sq = new IVRSequence(bdx, currentDS, items, isUndefined);
    }
    for (ByteItem item in items) item.addSQ(sq);
    _log.debugUp('$ree $sq');
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [ByteItem] or Fragment.
  ByteItem _readItem() {
    int xxx = rIndex;
    int start = rIndex; // start of elements
    int code = readTagCode();
    int vfLength = readUint32();
    bool hadULength = false;
    _log.debug('$rbb item kItem(${toHex32(kItem)}), code ${toHex32(code)} '
        'vfLength($vfLength, 0x${toHex32(vfLength)})');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    ByteDataset parentDS = currentDS;
    Map<int, ByteElement> elements = <int, ByteElement>{};
    try {
      if (vfLength == 0) {
        _log.debug('*** Zero length explicit length item');
        _log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');
      } else if (vfLength == kUndefinedLength) {
        hadULength = true;
        while (!_checkForItemDelimiter()) {
          ByteElement e = _readElement();
          elements[e.code] = e;
        }
        vfLength = rIndex - start;
      } else {
        int endOfVF = start + vfLength;
        while (rIndex <= endOfVF) {
          ByteElement e = _readElement();
          xxx = rIndex;
          elements[e.code] = e;
        }
      }
    } on EndOfDataException {
      _log.error('$ree _readItem end of data exception: @$rIndex');
      rethrow;
    } catch (e) {
      rootDS.hadParsingErrors = true;
      _log.error(e);
      rethrow;
    } finally {
      // Restore previous parent
      currentDS = parentDS;
    }
    xxx = rIndex;
    ByteData bdx = _getElementBD(start, rIndex);
    var item = new ByteItem.fromByteData(
        bdx, parentDS, elements, vfLength, hadULength);
    _log.debug('$ree readItemElements: ${item.info} Items');
    return item;
  }

  ByteElement _readPixelData(int start, int vfLength, bool isEVR) {
    log.debug('$rbb _readPixelData: isEVR($isEVR), vfLength($vfLength)');
    int startOfVF = rIndex;
    int vfOffset = (isEVR) ? 12 : 8;
    assert(
        start == startOfVF - vfOffset,
        'start($start) != startOF($startOfVF) - $vfOffset($vfOffset) '
        '= ${startOfVF -vfOffset}');
    VFFragments fragments;
    if (vfLength == kUndefinedLength) {
      // Read until [kSequenceDelimiterItem] found.
      fragments = _readFragments();
      // [rIndex] at end of delimited Element.
//TODO: assert rIndex - 8 = kSequenceDelimiterItem
    } else {
      rIndex = startOfVF + vfLength;
      fragments;
    }
    var bdx = _getElementBD(start, rIndex);
    //   int rows = currentDS[PTag.kRows.code].value;
    //   int columns = currentDS[PTag.kColumns.code].value;
    ByteElement e = (isEVR)
        ? new EVRPixelData(bdx, fragments)
        : new IVRPixelData(bdx, fragments);
    log.debug('$ree _readPixelData: ${e.info}');
    return e;
  }

// TODO: move into Pixel Data
// & readElementExplicit
  /// Returns an [ByteItem] or Fragment.
  VFFragments _readFragments() {
    // rIndex at first kItem delimiter
    var fragments = <Uint8List>[];
    int code = readTagCode();
    do {
      assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
      int vfLength = readUint32();
      assert(
          vfLength != kUndefinedLength,
          'Invalid length: ${toDcm(
                vfLength)}');
      int startOfVF = rIndex;
      rIndex += vfLength;
      fragments.add(bd.buffer.asUint8List(startOfVF, rIndex - startOfVF));
      code = readTagCode();
    } while (code != kSequenceDelimitationItem);
    int vfLength = readUint32();
    if (vfLength != 0)
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
    _log.debug2('$rmm delimiter(${toHex32(delimiter)}), '
        'target(${toHex32(target)})');
    if (delimiter == target) {
      skip(4);
      int delimiterLength = readUint32();
      _log.debug2('$rmm delimiter Lengtth $delimiterLength');
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

  /// Returns the end of an Element with Undefined Length;
  /// Reads the Value Field until the [kSequenceDelimiter] is found.
  /// [rIndex] is after delimiter at end of Value Field.
  int _findEndOfVF(int vfLength) {
    assert(vfLength == kUndefinedLength);
    while (isReadable) {
      if (readUint16() != kDelimiterFirst16Bits) continue;
      if (readUint16() != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    int delimiterLength = readUint32();
    if (delimiterLength != 0) _delimiterLengthFieldWarning(delimiterLength);
    return rIndex;
  }

  // Enhancement
//  int _readPrivateGroup(int group) { return 2; }

// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (!hadFMI || !hadFMI || !rootDS.hasSupportedTransferSyntax) return null;
    return rootDS.transferSyntax;
  }

  ByteElement _readElement() => (rootDS.isEVR) ? _readEVR() : _readIVR();

  ByteElement xReadPublicElement() => _readElement();

  // External Interface for testing
  ByteElement xReadPGLength() => _readElement();

  // External Interface for testing
  ByteElement xReadPrivateIllegal(
    int code,
  ) =>
      _readElement();

  // External Interface for testing
  ByteElement xReadPrivateCreator() => _readElement();

  // External Interface for testing
  ByteElement xReadPrivateData(
    ByteElement pc,
  ) {
    //  _TagMaker maker =
    //      (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
    return _readElement();
  }

  // Reads
  ByteDataset xReadDataset() {
    _log.debug('$rbb readDataset: isEVR(${rootDS.isEVR})');
    while (isReadable) {
      var e = _readElement();
      rootDS.add(e);
      e = rootDS[e.code];
      assert(e == e);
    }
    _log.debug('$ree end readDataset: isEVR(${rootDS.isEVR})');
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
    DcmReader reader =
        new DcmReader.fromBytes(bytes, fmi, path: path, targetTS: targetTS);
    if (fmiOnly) return (reader.hadFMI) ? reader.rootDS : null;

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
