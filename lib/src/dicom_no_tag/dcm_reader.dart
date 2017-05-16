// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:convertX/src/exception.dart';
import 'package:dictionary/dictionary.dart';

import 'byte_dataset.dart';
import 'byte_element.dart';
import 'utils.dart';

const List<int> _undefinedLengthElements = const <int>[
  kOBCode,
  kOWCode,
  kUNCode
];

//bool _undefinedAllowed(int vrCode) =>
// _undefinedLengthElements.contains(vrCode);

//TODO: remove log.debug when working

//TODO: rewrite all comments to reflect current state of code

/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
//typedef Element<E> VFReader<E>(int tag, VR<E> vr, int vfLength);

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
class DcmReader {
  ///TODO: doc
  static final Logger log = new Logger("DcmReader", watermark: Severity.config);

  /// The source of the [Uint8List] being read.
  final String path;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  final bool allowImplicitLittleEndian;
  final bool allowMissingFMI;
  final TransferSyntax targetTS;

  /// The root Dataset for the object being read.
  final RootByteDataset rootDS;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  ByteDataset _currentDS;
  bool _hadPrefix;

  // **** Reader fields ****

  final ByteData bd;
  final int endOfBD;
  int _rIndex = 0;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReader(this.bd,
      {this.path = "",
      this.throwOnError = true,
      this.allowImplicitLittleEndian = true,
      this.allowMissingFMI = false,
      this.targetTS})
      : endOfBD = bd.lengthInBytes,
        rootDS = new RootByteDataset.fromByteData(bd, hadUndefinedLength: true) {
    _warnIfShortFile();
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory DcmReader.fromList(List<int> list,
      {bool throwOnError = false,
      String path = "",
      bool allowImplicitLittleEndian = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    RootByteDataset rootDS = new RootByteDataset.fromByteData(bd, hadUndefinedLength:
    true);
    return new DcmReader._(bd, path, throwOnError, allowImplicitLittleEndian,
        allowMissingFMI, targetTS, rootDS);
  }

  DcmReader._(
      this.bd,
      this.path,
      this.throwOnError,
      this.allowImplicitLittleEndian,
      this.allowMissingFMI,
      this.targetTS,
      this.rootDS)
      : endOfBD = bd.lengthInBytes {
    _warnIfShortFile();
  }

  bool get _isReadable => _rIndex < endOfBD;

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => (_wasRead == null) ? false : _wasRead;
  bool _wasRead;

  set wasRead(bool v) => _wasRead ??= v;

  /// [true] if the source [ByteData] have been read.
  bool get hasParsingErrors =>
      (_hasParsingErrors == null) ? false : _hasParsingErrors;
  bool _hasParsingErrors;

  /// [true] if the source contained a DICOM Preamble and Prefix.
  bool get hadPrefix => rootDS.hadPrefix;

  /// [true] if the source contained DICOM File Meta Information (FMI).
  bool get hasFMI => rootDS.hasFMI;

  /// [true] if the source of this [RootByteDataset] had trailing zeros following
  /// the last [ByteElement] of the [ByteDataset].
  bool get hadTrailingZeros => rootDS.hadTrailingZeros;

  /// The current readIndex as a string.
  String get rrr => 'R@$_rIndex';

  /// The beginning of reading an [ByteElement] or [ByteItem].
  String get rbb => '> $rrr';

  /// In the middle of reading an [ByteElement] or [ByteItem]
  String get rmm => '| $rrr';

  /// The end of reading an [ByteElement] or [ByteItem]
  String get ree => '< $rrr';

  int _readUint16() {
    int v = bd.getUint16(_rIndex, Endianness.HOST_ENDIAN);
    _rIndex += 2;
    return v;
  }

  int _readUint32() {
    int v = bd.getUint32(_rIndex, Endianness.HOST_ENDIAN);
    _rIndex += 4;
    return v;
  }

  bool _inRange(int index) => index >= 0 || index < endOfBD;

  int _skip(int n) {
    int index = _rIndex + n;
    if (_inRange(index)) _rIndex = index;
    return _rIndex;
  }

  Uint8List _readChars(int length) {
    var chars = bd.buffer.asUint8List(_rIndex, length);
    _rIndex += length;
    return chars;
  }

  String _readAsciiString(int length) {
    var s = ASCII.decode(_readChars(length));
    return s;
  }

//  String _readUtf8String(int length) => UTF8.decode(_readChars(length));

  // **** DICOM encoding stuff ****

  /// Peek at next tag - doesn't move the [_rIndex].
  int _peekTagCode() {
    int group = bd.getUint16(_rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(_rIndex + 2, Endianness.HOST_ENDIAN);
    return (group << 16) + elt;
  }

  /// Reads
  int _readTagCode() {
  //  int group = _readUint16();
  //  int elt = _readUint16();
    int group = bd.getUint16(_rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(_rIndex + 2, Endianness.HOST_ENDIAN);
    _rIndex += 4;
    return (group << 16) + elt;
  }

  /// Returns [true] if the [ByteDataset] being read has an
  /// Explicit VR Transfer Syntax.
  bool get _isExplicitVR => rootDS.isExplicitVR;

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: '
      '${_currentDS.info}';

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [ByteElement]s were present; otherwise, returns null.
  RootByteDataset readFMI() {
    _currentDS = rootDS;
    log.debugDown('$rbb readFmi($_currentDS)');
    if (_hadPrefix == null) _readPrefix();
    log.debug2('$rmm readFMI: prefix($hadPrefix) $rootDS');
    if (!hadPrefix) return null;
    int start = _rIndex; //TODO: test this
    int code;
    try {
      while (_isReadable) {
        log.debugDown('$rbb readFMI loop:');
  //      var bytes = bd.buffer.asUint8List(_rIndex, 12);
        code = _peekTagCode();
        if (code >= 0x00080000) {
          break;
        } else if (code == 0) {
          zeroEncountered(code);
          return rootDS;
        } else {
          ByteElement e = _readElement(true);
          rootDS.add(e.code, e);
          log.debugUp('$ree readFMI loop: $e');
        }
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hasParsingErrors = true;
      log.debugUp('$ree readFMI TS catch: $x');
      rethrow;
    } catch (x) {
      if (code == 0) zeroEncountered(code);
      _hasParsingErrors = true;
      log.error('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = start;
      rethrow;
    }
    rootDS.tsIsNowReady();
    log.debugUp('$ree readFmi: ${rootDS.transferSyntax}\n   ${rootDS.info}');
    return rootDS;
  }

  /// Reads a [RootByteDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootByteDataset readRootDataset({bool allowMissingFMI = false}) {
    _currentDS = rootDS;
    var ds = readFMI();
    if (ds == null) return null;
    assert(ds == rootDS);

    //TODO: move TS processing to separate loop - maybe in dataset
    log.debug('$rmm tsString: "${rootDS.transferSyntaxString}"');
    log.debug('$rmm ${rootDS.transferSyntax}');
    if (!allowMissingFMI && !rootDS.hasFMI) return null;

    log.debug('$rbb targetTS: $targetTS');
    TransferSyntax ts = rootDS.transferSyntax;
    if (targetTS != null && ts != targetTS) return rootDS;

    log.debug('$rmm readRootDataset: TS($ts)}, isExplicitVR: $_isExplicitVR');
    if (!rootDS.hasValidTransferSyntax) {
      _hasParsingErrors = true;
      if (throwOnError) throw new InvalidTransferSyntaxError(ts, log);
      return rootDS;
    }
    if (ts == TransferSyntax.kExplicitVRBigEndian) {
      _hasParsingErrors = true;
      if (throwOnError) throw new InvalidTransferSyntaxError(ts);
      return rootDS;
    }

    _readDataset(rootDS);
    log.debug('$ree readRootDataset: ${rootDS.info}');
    return rootDS;
  }

  void _readDataset(ByteDataset ds) {
    assert(_currentDS != null);
    log.debug('$rbb readDataset: isExplicitVR(${ds.isExplicitVR})');
    while (_isReadable) {
      ByteElement e = _readElement(ds.isExplicitVR);
      _currentDS.add(e.code, e);
    }
    log.debug('$ree end readDataset: isExplicitVR(${ds.isExplicitVR})');
  }

  bool _readPrefix() {
    if (_rIndex != 0) {
      log.error('Attempt to read DICOM Prefix at ByteData[$_rIndex]');
      return false;
    }
    if (_hadPrefix != null) {
      log.error('Attempt to re-read DICOM Preamble and Prefix.');
      return false;
    }
    _skip(128);
    final String prefix = _readAsciiString(4);
    bool v = (prefix == "DICM") ? true : false;
    _hadPrefix = v;
    rootDS.hadPrefix = v;
    if (v == false) {
      log.warn('_hasPrefix: No DICOM Prefix present');
      _skip(-132);
    }
    return v;
  }

  ByteElement _readElement([bool isExplicitVR = true]) {
  //  log.debug('$rbb readElement...');
    int code = _readTagCode();
    // Sometimes there are zeros at the end of the file
    if (code == 0) zeroEncountered(code);
    ByteElement e = (isExplicitVR) ? _readEVR(code) : _readIVR(code);
  //  log.debug('$ree readElement: $e');
    return e;
  }

  ByteElement _readEVR(int code) {
    int start = _rIndex - 4; // for code
    int vrCode = _readUint16();
    if (vrCode == kSQCode) {
      _skip(2);
      return _readSequence(code, 12, true);
    }
    VR vr = VR.lookup(vrCode);
    assert(vr != null, 'Invalid null VR: vrCode(${toHex16(vrCode)})');
   // log.debug1('$rbb _readEVR: start($start), $vr');
    int eLength;
    if (vr.hasShortVF) {
      eLength = 8 + _readUint16();
      _rIndex = start + eLength;
    } else {
      _skip(2);
      int vfLength = _readUint32();
      if (vfLength == kUndefinedLength) {
        int endOfVF = _findEndOfVF(vfLength);
        eLength = endOfVF - start;
        _rIndex = endOfVF + 8;
      } else {
        eLength = 12 + vfLength;
        _rIndex = start + eLength;
      }
    }
    ByteData bdx = _getElementBD(start, eLength);
    var e = new EVRElement(bdx);
 //   log.debug1('$ree _readEVR: $e');

    return e;
  }

  bool zeroEncountered(int code) {
    int mark = _rIndex - 4;
    log.warn('$rmm Zero code($code) encountered @$mark');
  //  log.debug('_rIndex: $_rIndex');
    while (_isReadable) {
      int v = _readUint32();
      if (v != 0) {
        _rIndex = mark - 8;
        while (_isReadable && _rIndex < (mark + 40)) {
          int tag = _peekTagCode();
          int val = _readUint32();
          var s = val.toString().padLeft(8, "0");
          log.debug('$rmm ${toDcm(tag)} $s');
        }
        _hasParsingErrors = true;
        throw "bad code ${toDcm(code)}";
      }
      rootDS.hadTrailingZeros = true;
    }
    log.warn('returning from reading zeros at bytes @$_rIndex in "$path"');
    return true;
  }

  bool _isSequence() {
    int code = _peekTagCode();
    if (code == kItem || code == kSequenceDelimitationItem) {
      _skip(-4);
      return true;
    }
    return false;
  }

  ByteElement _readIVR(int code) {
    int start = _rIndex - 4; // for code
    int vfLength = _readUint32();
    if (_isSequence()) return _readSequence(code, 8, false);
  //  log.debug1('$rbb _readIVR: ${toDcm(code)} start($start), '
  //      'vfL($vfLength), endOfVF(${start + vfLength}');
    int eLength;
    if (vfLength == kUndefinedLength) {
      int endOfVF = _findEndOfVF(vfLength);
      eLength = endOfVF - start;
      _rIndex = endOfVF + 8;
    } else {
      eLength = 8 + vfLength;
      _rIndex = start + eLength;
    }
    ByteData bdx = _getElementBD(start, eLength);
    var e = new IVRElement(bdx);
  //  log.debug1('$ree _readIVR: $e');
    return e;
  }

  ByteData _getElementBD(int start, int eLength) {
    int endOfVF = start + eLength;
    if (endOfVF > endOfBD)
      log.error('$rmm endOfVR($endOfVF) is beyond the end of File: $path\n'
          '    start($start) + eLength($eLength) = $endOfVF > $endOfBD');
    return bd.buffer.asByteData(start, eLength);
  }

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads an EVR or IVR Sequence. The _readElementMethod detects Sequences.
  ByteElement _readSequence(int code, int headerLength, bool isEVR) {
    int vfLength = _readUint32();
    int start = _rIndex - headerLength;
    var hadUndefinedLength = (vfLength == kUndefinedLength);
  //  log.debugDown('$rbb SQ${toDcm(code)} start($start) undefinedLength'
  //      '($hadUndefinedLength), vfLength(${toHex32(vfLength)}, $vfLength)');
    int endOfVF;
    List<ByteItem> items = <ByteItem>[];
    if (hadUndefinedLength) {
  //    log.debug1('$rmm SQ${toDcm(code)} Undefined Length');
      while (!_checkForSequenceDelimiter()) items.add(_readItem(isEVR));
      endOfVF = _rIndex;
  //    log.debug1('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
  //    log.debug1('$rmm SQ: ${toDcm(code)} vfLength($vfLength)');
      endOfVF = start + headerLength + vfLength;
      while (_rIndex < endOfVF) items.add(_readItem(isEVR));
 //     log.debug1('$rmm SQ Length($vfLength) start($start) endOfVF($endOfVF)');
    }
    var e = bd.buffer.asByteData(start, endOfVF - start);
    SQ sq;
    //TODO: should be able to fix the type issue
    if (isEVR) {
      sq = new EVRSequence(e, _currentDS, items, hadUndefinedLength);
    } else {
      sq = new IVRSequence(e, _currentDS, items, hadUndefinedLength);
    }
    for (ByteItem item in items) item.addSQ(sq);
  //  log.debugUp('$ree $sq');
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [ByteItem] or Fragment.
  ByteItem _readItem(bool isExplicitVR) {
    int start = _rIndex;
    int code = _readTagCode();
 //   log.debug('$rbb item kItem(${toHex32(kItem)}, code ${toHex32(code)}');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
    int vfLength = _readUint32();
  //  log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    ByteDataset parentDS = _currentDS;
    Map<int, ByteElement> elements = <int, ByteElement>{};
    bool hadUndefinedLength = vfLength == kUndefinedLength;
  //  log.debug1('$rmm readItem hadUndefinedLength=$hadUndefinedLength');
    int endOfVF;
    try {
      if (hadUndefinedLength) {
        while (!_checkForItemDelimiter()) {
          ByteElement e = _readElement(isExplicitVR);
          elements[e.code] = e;
        }
        endOfVF = _rIndex;
      } else {
        endOfVF = start + vfLength;
        while (_rIndex < endOfVF) {
          ByteElement e = _readElement(isExplicitVR);
          elements[e.code] = e;
        }
      }
    } on EndOfDataException {
  //    log.debug1('_readItem end of data exception: @$_rIndex');
      rethrow;
    } catch (e) {
      _hasParsingErrors = true;
      log.error(e);
      rethrow;
    } finally {
      // Restore previous parent
      _currentDS = parentDS;
    }

    var bytes = bd.buffer.asByteData(start, endOfVF - start);
    var item = new ByteItem.fromByteData(bytes, parentDS, elements,
        hadUndefinedLength);
  //  log.debug('$ree readItemElements: ${item.length} Items');
    return item;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  bool _checkForSequenceDelimiter() {
  //  log.debug('$rmm check SQ Delimiter');
    return _checkForDelimiter(kSequenceDelimitationItem);
  }

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  bool _checkForItemDelimiter() {
  //  log.debug('$rmm check Item Delimiter');
    return _checkForDelimiter(kItemDelimitationItem);
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced past the Value Length Field;
  /// otherwise, readIndex does not change
  bool _checkForDelimiter(int target) {
    int delimiter = _peekTagCode();
  //  log.debug('$rmm delimiter(${toHex32(delimiter)}), '
  //      'target(${toHex32(target)})');
    if (delimiter == target) {
      _skip(4);
      int delimiterLength = _readUint32();
      if (delimiterLength != 0) _delimiterLengthFieldWarning(delimiterLength);
      return true;
    }
    return false;
  }

  void _delimiterLengthFieldWarning(int dLength) {
    rootDS.hadNonZeroDelimiterLength = true;
    log.warn('$rmm: Encountered a delimiter with a non zero length($dLength)'
        ' field');
  }

  /// Reads the Value Field until the [kSequenceDelimiter] is found.
  int _findEndOfVF(int vfLength) {
   // log.debug1('$rbb _findLength: vfLength(0x${toHex32(vfLength)}})');
    if (vfLength == kUndefinedLength) {
      while (_isReadable) {
        if (_readUint16() != kDelimiterFirst16Bits) continue;
        if (_readUint16() != kSequenceDelimiterLast16Bits) continue;
        break;
      }
      // int delimiterLengthField = readUint32();
      int delimiterLength = _readUint32();
      if (delimiterLength != 0) _delimiterLengthFieldWarning(delimiterLength);
      int endOfVF = _rIndex - 8;
      //   _rIndex = mark;
  //    log.debug1('$ree start($mark), end($endOfVF), '
  //        'vfLength(${endOfVF - mark}');
      return endOfVF;
    }
    _hasParsingErrors = true;
    throw "vfLength($vfLength) not kUndefinedLength";
  }

  void _warnIfShortFile() {
    int length = bd.lengthInBytes;
    if (length < rootDS.smallFileThreshold) {
      var s = 'Short file error: length(${bd.lengthInBytes}) $path';
      _hasParsingErrors = true;
      throw s;
    }
    if (length < rootDS.smallFileThreshold)
      log.warn('**** Trying to read $length bytes');
  }


// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (checkForPrefix && !_readPrefix()) return null;
    readFMI();
    if (!rootDS.hasFMI || !rootDS.hasValidTransferSyntax) return null;
    return rootDS.transferSyntax;
  }

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
    log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    while (_isReadable) {
      var e = _readElement(isExplicitVR);
      rootDS.add(e.code, e);
      e = rootDS[e.code];
      assert(e == e);
    }
    log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    return _currentDS;
  }

  static RootByteDataset fmi(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.readFMI();
  }

  static RootByteDataset rootDataset(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.readRootDataset();
  }

  static RootByteDataset dataset(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.xReadDataset();
  }

  static RootByteDataset readBytes(Uint8List bytes,
      {String path: "", bool fmiOnly = false, TransferSyntax targetTS}) {
    if (fmiOnly) return DcmReader.fmi(bytes, path: path);
    return DcmReader.rootDataset(bytes, path: path);
  }

  static RootByteDataset readFile(File file,
      {bool fmiOnly = false, TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }
}

