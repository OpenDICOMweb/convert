// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:convertX/src/exception.dart';
import 'package:dictionary/dictionary.dart';

import 'dataset.dart';
import 'element.dart';
import 'utils.dart';

const int kSQCode = 0x5153;
const int kOBCode = 0x424f;
const int kOWCode = 0x574f;
const int kUNCode = 0x4e55;

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

/// A library for parsing [Uint8List] containing DICOM File Format [Dataset]s.
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
  static final Logger log = new Logger("DcmReader", watermark: Severity.info);

  /// The source of the [Uint8List] being read.
  final String path;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  final bool allowImplicitLittleEndian;
  final bool allowMissingFMI;
  final TransferSyntax targetTS;

  bool _hadPrefix;
  bool _fmiPresent;

  /// The root Dataset for the object being read.
  final RootDataset _rootDS;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  Dataset _currentDS;

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
        _rootDS = new RootDataset(bd, true) {
    _warnIfShortFile(bd, path);
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
    _warnIfShortFile(bd, path);
    RootDataset rootDS = new RootDataset(bd, true);
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
      this._rootDS)
      : endOfBD = bd.lengthInBytes;

  bool get _isReadable => _rIndex < endOfBD;

  bool get isFMIPresent => _fmiPresent;

  /// The current readIndex as a string.
  String get rrr => 'R@$_rIndex';

  /// The beginning of reading an [Element] or [Item].
  String get rbb => '> $rrr';

  /// In the middle of reading an [Element] or [Item]
  String get rmm => '| $rrr';

  /// The end of reading an [Element] or [Item]
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

  bool _inRange(int index) => index < 0 || index >= endOfBD;

  int _skip(int n) {
    int index = _rIndex + n;
    if (!_inRange(index)) _rIndex = index;
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
    final int group = bd.getUint16(_rIndex, Endianness.HOST_ENDIAN);
    final int elt = bd.getUint16(_rIndex + 2, Endianness.HOST_ENDIAN);
    return (group << 16) + elt;
  }

  int _readTagCode() {
    int group = _readUint16();
    int elt = _readUint16();
    return (group << 16) + elt;
  }

  /// Returns [true] if the [Dataset] being read has an
  /// Explicit VR Transfer Syntax.
  bool get _isExplicitVR => _rootDS.isExplicitVR;

  String get info => '$runtimeType: rootDS: ${_rootDS.info}, currentDS: '
      '${_currentDS.info}';

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  RootDataset readFMI() {
    _currentDS = _rootDS;
    log.down;
    log.debug('$rbb readFmi($_currentDS)');
    _hadPrefix = _hasPrefix();
    log.debug2('$rmm readMFI: prefix($_hadPrefix) $_rootDS');
    if (!_hadPrefix) return null;
    int start = _rIndex; //TODO: test this
    int code;
    try {
      while (_isReadable) {
        log.down;
        log.debug1('$rbb readFMI loop:');
        var bytes = bd.buffer.asUint8List(_rIndex, 12);
        log.debug2('$rmm readFMI loop: $bytes');
        code = _peekTagCode();
        log.debug2('$rmm readFMI loop: code(${toDcm(code)})');
        if (code >= 0x00080000) {
          log.debug1('$ree End readFMI loop: skip ${toDcm(code)}');
          log.up;
          break;
        } else if (code == 0) {
          // Sometimes there are zeros at the end of the file
          zeroEncountered(code);
          return _rootDS;
        } else {
          var e = _readElement(true);
          log.debug1('$ree readFMI loop: $e');
          log.up;
        }
      }
    } on InvalidTransferSyntaxError catch (x) {
      log.debug('$ree readFMI TS catch: $x');
      log.up;
      rethrow;
    } catch (x) {
      if (code == 0) {
        zeroEncountered(code);
      }
      log.error('Failed to read FMI: "$path"');
      log.error('Exception: $x');
      log.error('File length: ${bd.lengthInBytes}');
      log.debug('$ree readFMI catch: $x');
      _rIndex = start;
      log.up;
      rethrow;
    }
    log.debug('$ree readFmi: ${_rootDS.transferSyntax}\n   ${_rootDS.info}');
    //   var ts = _rootDS.transferSyntax;
    //   if (targetTS != null && ts != targetTS) return null;
    log.up;
    _fmiPresent = true;
    return _rootDS;
  }

  /// Reads a [RootDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootDataset readRootDataset({bool allowMissingFMI = false}) {
    _currentDS = _rootDS;
    var ds = readFMI();
    if (ds == null) return null;
    assert(ds == _rootDS);
    if (!allowMissingFMI && !_rootDS.isFMIPresent) return null;

    log.debug('$rbb targetTS: $targetTS');
    TransferSyntax ts = _rootDS.transferSyntax;
    if (targetTS != null && ts != targetTS) return _rootDS;

    log.debug('$rmm readRootDataset: TS($ts)}, isExplicitVR: $_isExplicitVR');
    if (!_rootDS.hasValidTransferSyntax) {
      if (throwOnError) throw new InvalidTransferSyntaxError(ts, log);
      return _rootDS;
    }
    if (ts == TransferSyntax.kExplicitVRBigEndian) {
      if (throwOnError)
        throw new InvalidTransferSyntaxError(ts);
      return _rootDS;
    }

    _readDataset(_rootDS, _rootDS.isExplicitVR);
    log.debug('$ree readRootDataset: ${_rootDS.info}');
    return _rootDS;
  }

  void _readDataset(Dataset ds, bool isExplicitVR) {
    log.down;
    assert(_currentDS != null);
    log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    while (_isReadable) _readElement(isExplicitVR);
    log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    log.up;
  }

  bool _hasPrefix() {
    _skip(128);
    final String prefix = _readAsciiString(4);
    if (prefix == "DICM") return true;
    log.warn('_hasPrefix: No DICOM Prefix present');
    _skip(-132);
    return false;
  }

  Element _readElement([bool isExplicitVR = true]) {
    log.down;
    int code = _readTagCode();
    if (code == 0) {
      // Sometimes there are zeros at the end of the file
      zeroEncountered(code);
    }
    log.debug('$rbb readElement: _readCode${toDcm(code)}');
    Element e = (isExplicitVR) ? _readEVR(code) : _readIVR(code);
    _rootDS.add(code, e);
    log.debug('$ree readElement: $e');
    log.up;
    return e;
  }

  Element _readEVR(int code) {
    int start = _rIndex - 4; // for code
    int vrCode = _readUint16();
    if (vrCode == kSQCode) {
      _skip(2);
      return _readSequence(code, true);
    }
    VR vr = VR.lookup(vrCode);
    assert(vr != null, 'Invalid null VR: vrCode(${toHex16(vrCode)})');
    log.down;
    log.debug1('$rbb _readEVR: start($start), $vr');
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
    log.debug1('$ree _readEVR: $e');
    log.up;
    return e;
  }

  void zeroEncountered(int code) {
    int mark = _rIndex - 4;
    log.warn('$rmm Zero code($code) encountered @$mark');
    log.debug('_rIndex: $_rIndex');
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
        throw "bad code ${toDcm(code)}";
      }
    }
    log.warn('returning from reading zeros at end of file @$_rIndex');
    return null;
  }

  Element _readIVR(int code) {
    int start = _rIndex - 4; // for code
    if (_isSequence()) return _readSequence(code, false);

    int vfLength = _readUint32();
    log.down;
    log.debug1('$rbb _readIVR: ${toDcm(code)} start($start), '
        'vfL($vfLength), endOfVF(${start + vfLength}');
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
    log.debug1('$ree _readIVR: $e');
    log.up;
    return e;
  }

  ByteData _getElementBD(int start, int eLength) {
    int endOfVF = start + eLength;
    if (endOfVF > endOfBD)
      log.error('$rmm endOfVR($endOfVF) is beyond the end of File: $path\n'
          '    start($start) + eLength($eLength) = $endOfVF > $endOfBD');
    return bd.buffer.asByteData(start, eLength);
  }


  bool _isSequence() {
    int code = _peekTagCode();
    return (code == kItem || code == kSequenceDelimitationItem) ? true : false;
  }

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads an EVR or IVR Sequence. The _readElementMethod detects Sequences.
  Element _readSequence(int code, bool isEVR) {
    int vfLength = _readUint32();
    log.down;
    // code, vr (if present) and vfLength have already been read;
    int headerLength = (isEVR) ? 12 : 8;
    int start = _rIndex - headerLength;
    var hadUndefinedLength = (vfLength == kUndefinedLength);
    log.debug('$rbb SQ${toDcm(code)} start($start) undefinedLength'
        '($hadUndefinedLength), vfLength(${toHex32(vfLength)}, $vfLength)');

    int endOfVF;
    List<Item> items = <Item>[];
    if (hadUndefinedLength) {
      log.debug1('$rmm SQ${toDcm(code)} Undefined Length');
      while (!_checkForSequenceDelimiter()) items.add(_readItem(isEVR));
      endOfVF = _rIndex;
      log.debug1('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
      log.debug1('$rmm SQ: ${toDcm(code)} vfLength($vfLength)');
      endOfVF = start + headerLength + vfLength;
      while (_rIndex < endOfVF) items.add(_readItem(isEVR));
      log.debug1('$rmm SQ Length($vfLength) start($start) endOfVF($endOfVF)');
    }

    var e = bd.buffer.asByteData(start, endOfVF - start);
    var sq;
    if (isEVR) {
      sq = new EVRSequence(e, _currentDS, items, hadUndefinedLength);
    } else {
      sq = new IVRSequence(e, _currentDS, items, hadUndefinedLength);
    }
    for (Item item in items) item.addSQ(sq);
    log.debug('$ree $sq');
    log.up;
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [Item] or Fragment.
  Item _readItem(isExplicitVR) {
    log.down;
    int start = _rIndex;
    int code = _readTagCode();
    log.debug('$rbb item kItem(${toHex32(kItem)}, code ${toHex32(code)}');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
    int vfLength = _readUint32();
    log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    Dataset parentDS = _currentDS;
    Map<int, Element> elements = <int, Element>{};
    bool hadUndefinedLength = vfLength == kUndefinedLength;
    log.debug1('$rmm readItem hadUndefinedLength=$hadUndefinedLength');
    int endOfVF;
    try {
      if (vfLength == kUndefinedLength) {
        hadUndefinedLength = true;
        while (!_checkForItemDelimiter()) {
          Element e = _readElement(isExplicitVR);
          elements[e.code] = e;
        }
        endOfVF = _rIndex;
      } else {
        endOfVF = start + vfLength;
        while (_rIndex < endOfVF) {
          Element e = _readElement(isExplicitVR);
          elements[e.code] = e;
        }
      }
    } on EndOfDataException {
      log.debug1('_readItem');
      log.up;
      rethrow;
    } catch (e) {
      log.debug1(e);
      rethrow;
    } finally {
      // Restore previous parent
      _currentDS = parentDS;
    }

    var e = bd.buffer.asByteData(start, endOfVF - start);
    var item = new Item(e, parentDS, elements, hadUndefinedLength);
    log.debug('$ree readItemElements: ${item.length} Items');
    log.up;
    return item;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  bool _checkForSequenceDelimiter() {
    log.debug('$rmm check SQ Delimiter');
    return _checkForDelimiter(kSequenceDelimitationItem);
  }

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  bool _checkForItemDelimiter() {
    log.debug('$rmm check Item Delimiter');
    return _checkForDelimiter(kItemDelimitationItem);
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced past the Value Length Field;
  /// otherwise, readIndex does not change
  bool _checkForDelimiter(int target) {
    int delimiter = _peekTagCode();
    log.debug('$rmm delimiter(${toHex32(delimiter)}), '
        'target(${toHex32(target)})');
    if (delimiter == target) {
      _skip(4);
      int dLength = _readUint32();
      if (dLength != 0) _non0DelimiterLengthWarn(dLength);
      return true;
    }
    return false;
  }

  LogRecord _non0DelimiterLengthWarn(int dLength) =>
      log.warn('$rmm: Encountered non zero length($dLength)'
          ' following Undefined Length delimeter');

  static const int kReverseSQDelimiter = 0xe0ddfffe;

  /// Reads the Value Field until the [kSequenceDelimiter] is found.
  int _findEndOfVF(int vfLength) {
    log.down;
    log.debug1('$rbb _findLength: vfLength(0x${toHex32(vfLength)}})');
    if (vfLength == kUndefinedLength) {
      int mark = _rIndex;
      while (_isReadable) {
        //TODO: make one call by reversing kSequenceDelimiter
        //   if (_readUint32() != kReverseSQDelimiter) continue;
        if (_readUint16() != kDelimiterFirst16Bits) continue;
        if (_readUint16() != kSequenceDelimiterLast16Bits) continue;
        break;
      }
      // int delimiterLengthField = readUint32();
      int lengthField = _readUint32();
      if (lengthField != 0)
        log.warn('Sequence Delimiter with non-zero value: $lengthField');
      int endOfVF = _rIndex - 8;
      //   _rIndex = mark;
      log.debug1('$ree start($mark), end($endOfVF), '
          'vfLength(${endOfVF - mark}');
      log.up;
      return endOfVF;
    }
    throw "vfLength($vfLength) not kUndefinedLength";
  }

  static const int _kSmallFileThreshold = 1024;

  static void _warnIfShortFile(ByteData bd, String path) {
    int length = bd.lengthInBytes;
    if (length < 200) {
      var s = 'Short file error: length(${bd.lengthInBytes}) $path';
      throw s;
    }
    if (length < _kSmallFileThreshold)
      log.debug('**** Trying to read $length bytes');
  }

/*
  //TODO: improve
  void _debugReader(int code, obj, [int vfLength, String msg]) {
    // [readIndex] should be at start + 6
    String label;
    if (code is int) {
      label = toHex32(code);
    } else {
      label = code.toString();
    }
    var s = '''

debugReader:
  $rrr: $label $msg
  // Urgent: fix next two lines
    short Length: ${Int.hex(_readUint16(), 4)}
    long Length: ${Int.hex(_readUint16(), 8)}
     bytes: [${bdToHex(bd, _rIndex - 12, _rIndex + 12, _rIndex)}]
    string: "${toAscii(bd, _rIndex - 12, _rIndex + 12, _rIndex)}"
''';
    log.error(s);
  }
*/
// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (checkForPrefix && !_hasPrefix()) return null;
    readFMI();
    if (!_rootDS.isFMIPresent || !_rootDS.hasValidTransferSyntax) return null;
    return _rootDS.transferSyntax;
  }

  Element xReadPublicElement([bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPGLength([bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPrivateIllegal(int code, [bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPrivateCreator([bool isExplicitVR = true]) =>
      _readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPrivateData(Element pc, [bool isExplicitVR = true]) {
    //  _TagMaker maker =
    //      (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
    return _readElement(isExplicitVR);
  }

  // Reads
  Dataset xReadDataset([bool isExplicitVR = true]) {
    log.down;
    log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    while (_isReadable) {
      var e = _readElement(isExplicitVR);
      _rootDS.add(e.code, e);
      e = _rootDS[e.code];
      assert(e == e);
    }
    log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    log.up;
    return _currentDS;
  }

  static RootDataset fmi(Uint8List bytes,
      [String path = "", TransferSyntax targetTS]) {
    ByteData bd =
    bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.readFMI();
  }

  static RootDataset rootDataset(Uint8List bytes,
      [String path = "", TransferSyntax targetTS]) {
    ByteData bd =
    bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.readRootDataset();
  }

  static RootDataset dataset(Uint8List bytes,
      [String path = "", TransferSyntax targetTS]) {
    ByteData bd =
    bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.xReadDataset();
  }
}

class InvalidTransferSyntaxError extends Error {
  final TransferSyntax ts;

  InvalidTransferSyntaxError(this.ts, [Logger log]) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => '$runtimeType:\n  Element(${ts.info})';
}
