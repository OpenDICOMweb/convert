// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/dcm_reader_base.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dictionary/dictionary.dart';

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

// Useful for debugging
//                     kItem: 0xfffee000 4294893568
// kSequenceDelimitationItem: 0xfffee0dd 4294893789
//     kItemDelimitationItem: 0xfffee00d 4294893581
//          kUndefinedLength: 0xffffffff 4294967295

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
class DcmByteReader extends DcmReaderBase {
  static final Logger _log = new Logger("DcmReader", watermark: Severity.debug2);
  RootByteDataset rootDS;
  ByteDataset currentDS;
  bool _afterPixelData;

  //TODO: Doc
  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  DcmByteReader(ByteData bd,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = false})
      : super(bd, <int, ByteElement>{},
            path: path,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD) {
    rootDS = new RootByteDataset(bd, path: path);
    currentDS = rootDS;
  }

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  factory DcmByteReader.fromBytes(Uint8List bytes,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    var bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    return new DcmByteReader(bd,
        path: path, throwOnError: throwOnError, targetTS: targetTS, reUseBD: reUseBD);
  }

  /// Reads a [RootByteDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootByteDataset readRootDataset({bool allowMissingFMI = false}) {
    _log.debug1('$rbb readRootDataset: endOfBD($endOfBD) Part10($part10})');
    hadPrefix = readPrefix(bd);
    rootDS.hasCmdElements = _readUntil(0x00020000);
    hadFMI = _readUntil(0x00030000);
    rootDS.isDicomDir = _readUntil(0x00050000);

    if (!hadFMI && !allowMissingFMI && !hadFMI) return null;
    _log.info('  isEVR: ${rootDS.isEVR}');
    currentDS = rootDS;
    int endOfDS = endOfBD;
    var e = _readElement();
    // Check for Group Length
    if (e.code == 0x00080000) {
      endOfDS == e.value;
      if (endOfBD > endOfDS) log.warn('endOfBD($endOfBD) > endOfDS($endOfDS)');
      currentDS.add(e);
      e = _readElement();
    }
    // Check for Specific Character Set
    if (e.code == 0x00080005) {
      // TODO: handle other Codecs here.
      _log.info('  (0005,0008) "${e.asStringList}"');
      if (e.value == "ISO_IR 100") ByteElement.codec = LATIN1;
      _log.debug('codec: ${ByteElement.codec}');
    }
    currentDS.add(e);
    _readDataset(currentDS, endOfDS);
    //   rootDS = currentDS;
    _log.debug1('$ree readRootDataset: ${rootDS.info}');
    return rootDS;
  }

  void _readDataset(ByteDataset ds, int endOfDS) {
    assert(currentDS != null);
    _log.debugDown('$rbb readDataset: isEVR(${ds.isEVR}), '
        'endOfDS($endOfDS)');
    try {
      while (rIndex < endOfDS) {
        var e = _readElement(ds.isEVR);
        currentDS.add(e);
        if (e.code == kPixelData) {
          if (rIndex < endOfBD) {
            _afterPixelData = true;
            _log.warn('**** Data after PixelData Element: '
                'rIndex($rIndex), endOfDS($endOfDS), endOfBD($endOfBD)');
            _log.warn('bd($rIndex - $endOfBD): '
                '${bd.buffer.asUint8List(rIndex, endOfBD)}');
            int code = peekTagCode();
            _log.warn('code(${toDcm(code)}');
            if (code > 0xFFFCFFFC) return;
          }
        }
      }
    } catch (e) {
      _log.error('$rmm    _readDataset Caught $e');
      _log.error('$ree    endOfDS($endOfDS} != rIndex($rIndex)');
      _log.up;
      if (_afterPixelData) {
        return;
      } else {
        rethrow;
      }
    }
    assert(endOfDS == rIndex, 'endOfDS($endOfDS} != rIndex($rIndex)');
    _log.debugUp('$ree end readDataset: isEVR(${ds.isEVR})');
  }

  ByteElement readElement([bool isEVR = true]) => _readElement();

  ByteElement _readElement([bool isEVR = true]) => (isEVR) ? _readEVR() : _readIVR;

  // bool beyondPixelData = false;
  ByteElement _readEVR() {
    int start = rIndex;
    int code = readTagCode();
    int vrCode = readUint16();
    assert(rIndex == start + 6);
    VR vr = VR.lookup(vrCode);
    assert(vr != null, 'Invalid null VR: vrCode(${toHex16(vrCode)})');

    if (vrCode == kSQCode) {
      skip(2);
      return _readSequence(code, start);
    }
    _log.down;
    _log.debug1('$rbb ${toDcm(code)} $vr');
    _log.debug1('$rmm     start($start) _readEVR: ');
    if (vr.hasShortVF) {
      int vfLength = readUint16();
      _log.debug1('$rmm     vfLength: $vfLength}');
      assert(rIndex == start + 8);
      rIndex += vfLength;
    } else {
      skip(2);
      int vfLength = readUint32();
      var s = (vfLength == kUndefinedLength) ? '0xFFFFFFFF' : '$vfLength';
      _log.debug1('$rmm     vfLength: $s');
      assert(rIndex == start + 12);
      if (code == kPixelData) {
        EVRPixelData e = _readPixelData(start, vfLength, true);
        _log.debug1('$ree    ${e.info} _readEVR: ');
        _log.up;
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
    _log.up;
    return e;
  }

  ByteElement _readIVR() {
    bool isSequence() {
      int delimiter = bd.getUint32(rIndex);
      //  int code = peekTagCode();
      if (delimiter == kItem32Bit || delimiter == kSequenceDelimitationItem32Bit) {
        skip(-4);
        return true;
      }
      return false;
    }

    int start = rIndex;
    _log.down;
    _log.debug('$rbb start: $start ');
    int code = readTagCode();
    _log.debug('$rmm code(${Tag.toDcm(code)}, $code) ');
    int vfLength = readUint32();
    _log.debug1('$rmm     vfLength: '
        '${(vfLength == kUndefinedLength) ? 0xFFFFFFFF : vfLength}');
    _log.debug1('$rbb _readIVR: start($start), ${toDcm(code)} '
        'vfLength($vfLength, ${toHex32(vfLength)}');
    if (isSequence()) return _readSequence(code, start);
    if (code == kPixelData) {
      IVRPixelData e = _readPixelData(start, vfLength, false);
      _log.debug1('$ree _readEVR: ${e.info}');
      _log.up;
      return e;
    }
    if (vfLength == kUndefinedLength) {
      rIndex = _findEndOfVF(vfLength);
    } else {
      rIndex += vfLength;
      _log.debug1('$rmm     vfLength: '
          '${(vfLength == kUndefinedLength) ? 0xFFFFFFFF : vfLength}');
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
    _log.up;
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
      while (!_checkForDelimiter(kSequenceDelimitationItem32Bit)) {
        items.add(_readItem());
      }
      endOfVF = rIndex;
      _log.debug2('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
      endOfVF = vfStart + vfLength;
      _log.debug2('$rmm SQ: ${toDcm(code)} vfL($vfLength), EOVF($endOfVF)');
      while (rIndex < endOfVF) {
        items.add(_readItem());
        //    xxx = rIndex;
      }
      _log.debug2('$rmm SQ VFL($vfLength) start($start) EOVF($endOfVF)');
    }

    // xxx = rIndex;
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
    int start = rIndex; // start of elements
    int code = readTagCode();
    int vfLength = readUint32();
    bool hadULength = false;
    _log.debugDown('$rbb Item${toDcm(kItem)}, code ${toHex32(code)} '
        'vfLength($vfLength, 0x${toHex32(vfLength)})');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    ByteDataset parentDS = currentDS;
    Map<int, ByteElement> map = <int, ByteElement>{};
    try {
      if (vfLength == 0) {
        _log.debug('*** Zero length explicit length item');
        _log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');
      } else if (vfLength == kUndefinedLength) {
        int start = rIndex;
        hadULength = true;
        while (!_checkForDelimiter(kItemDelimitationItem32Bit)) {
          ByteElement e = _readElement();
          map[e.code] = e;
        }
        vfLength = rIndex - start;
      } else {
        int endOfVF = start + vfLength;
        while (rIndex <= endOfVF) {
          ByteElement e = _readElement();
          map[e.code] = e;
        }
      }
    } on EndOfDataError catch (e, stacktrace) {
      _log.error('$ree _readItem end of data exception: @$rIndex');
      _log.error('e: $e');
      _log.error(stacktrace);
      rethrow;
    } catch (e, stacktrace) {
      hadParsingErrors = true;
      _log.error(e);
      _log.error(stacktrace);
      rethrow;
    } finally {
      // Restore previous parent
      currentDS = parentDS;
    }
    ByteData bdx = _getElementBD(start, rIndex);
    var item = new ByteItem.fromMap(bdx, parentDS, map, vfLength, hadULength);
    _log.debugUp('$ree Item: $item');
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
      // Read until [kSequenceDelimiterItem] found.[rIndex] at end of delimiter.
      fragments = _readFragments();
    } else {
      rIndex = startOfVF + vfLength;
    }
    var bdx = _getElementBD(start, rIndex);
    ByteElement e = (isEVR) ? new EVRPixelData(bdx, fragments) : new IVRPixelData(bdx, fragments);
    endOfPixelData = rIndex;
    _afterPixelData = true;
    if (endOfPixelData < endOfBD)
      log.warn('****  reading ${endOfBD - endOfPixelData} after Pixel Data');
    log.debug('$ree _readPixelData: ${e.info}');
    return e;
  }

// TODO: move into Pixel Data
// & readElementExplicit
  /// Returns an [ByteItem] or Fragment.
  VFFragments _readFragments() {
    log.down;
    log.debug('$rbb readFragements');
    // rIndex at first kItem delimiter
    var fragments = <Uint8List>[];
    int code = readTagCode();
    do {
      assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
      int vfLength = readUint32();
      assert(vfLength != kUndefinedLength, 'Invalid length: ${toDcm(vfLength)}');
      int startOfVF = rIndex;
      rIndex += vfLength;
      fragments.add(bd.buffer.asUint8List(startOfVF, rIndex - startOfVF));
      code = readTagCode();
    } while (code != kSequenceDelimitationItem);
    int vfLength = readUint32();
    if (vfLength != 0)
      log.warn('Pixel Data Sequence delimiter has non-zero '
          'value: $code/0x${toHex32(code)}');
    var vfFragments = new VFFragments(fragments);
    var delimiter = bd.getUint32(rIndex - 8);
    assert(delimiter == kSequenceDelimitationItem32Bit);
    log.debug('$ree readFragements: $vfFragments');
    log.up;
    return vfFragments;
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced past the Value Length Field;
  /// otherwise, readIndex does not change.
  /// Note: the [target] is 2x16bit Little Endian Values read as a 32bit value.
  bool _checkForDelimiter(int target) {
    int delimiter = bd.getUint32(rIndex);
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
    hadNonZeroDelimiterLength = true;
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

  /// Read File Meta Information (PS3.10).
  void readFmi([bool checkForPrefix = true]) {
    try {
      while (rIndex < endOfBD) {
        int code = peekTagCode();
        if (code >= 0x00030000) return;
        Element e = readElement();
        rootDS.add(e);
      }
    } catch (x) {
      hadParsingErrors = true;
      hadProblems = true;
      _log.warn('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      rIndex = 0;
      rethrow;
    }
    //  readFmi(fmi);
    if (rootDS.map.length == 0) return;
    // var ts = getTransferSyntax(rootDS.map);
    _log.warn('readFMI: bd.length(${bd.lengthInBytes} bbbbbbbbbtoo small');
  }

  /// Read Read Elements until a [code] >= [codeLimit]
  bool _readUntil(int codeLimit) {
    try {
      while (rIndex < endOfBD) {
        int code = peekTagCode();
        if (code >= codeLimit) break;
        Element e = readElement();
        rootDS.add(e);
      }
    } catch (x) {
      hadParsingErrors = true;
      hadProblems = true;
      _log.warn('Failed to readUntil ${toDcm(codeLimit)}: '
          '"$path"\nException: $x\n '
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      //    rIndex = 0;
      rethrow;
    }
    //  readFmi(fmi);
    if (rootDS.map.length == 0) return false;
    var ts = getTransferSyntax(rootDS.map);
    _log.warn('readFMI: bd.length(${bd.lengthInBytes} too small');
    return true;
  }

  // **** Static Methods

  static RootByteDataset readBytes(Uint8List bytes,
      {String path: "", bool fmiOnly = false, fast = true, TransferSyntax targetTS}) {
    if (bytes == null) throw new ArgumentError('readBytes: $bytes');
    if (bytes.length < 256) {
      log.error('**** DcmReader: Too few bytes: ${bytes.length} in $path');
      return null;
    }
    DcmByteReader reader = new DcmByteReader.fromBytes(bytes, path: path, targetTS: targetTS);
    if (fmiOnly) return (reader.hadFMI) ? reader.rootDS : null;
    return reader.readRootDataset();
  }

  static RootByteDataset readFile(File file,
      {bool fmiOnly = false, bool fast: false, TransferSyntax targetTS}) {
    if (file == null) throw new ArgumentError('readFile: $file');
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes, path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  static RootByteDataset readPath(String path,
          {bool fmiOnly = false, bool fast = false, TransferSyntax targetTS}) =>
      readFile(new File(path), fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);

  static ByteDataset read(from,
      {String path = "", bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    if (from is String) return readPath(from, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (from is File) return readFile(from, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (from is Uint8List)
      return readBytes(from, path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    throw new ArgumentError('$from');
  }

  static Instance readInstance(obj,
      {String path = "", bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    var rds = read(obj, path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    return new Instance.fromDataset(rds);
  }
}
