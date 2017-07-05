// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dictionary/dictionary.dart';
//import 'dataset.dart';
//import 'element.dart';
//import 'utils.dart';

/// Fix: move to constants in Dictionary
const int kSQCode = 0x5153;
const int kOBCode = 0x424f;
const int kOWCode = 0x574f;
const int kUNCode = 0x4e55;

const List<int> _undefinedLengthElements = const <int>[kOBCode, kOWCode, kUNCode];

//TODO: rewrite all comments to reflect current state of code

/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
typedef Element ElementMaker<V>(int code, VR<V> vr, int vfLength);

/// A [Converter] [Uint8List]s containing a [Dataset] encoded in the
/// application/dicom media type.

/// _Notes_:
/// 1. Reads and returns the Value Fields as they are in the data.
///  For example DcmReader does not trim whitespace from strings.
///  This is so they can be written out byte for byte as they were
///  read. and a byte-wise comparator will find them to be equal.
/// 2. All String manipulation should be handled by the containing [Element] itself.
/// 3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
class DcmReader {
  static const int shortFileThreshold = 1024;
  //TODO: remove log.debug when working
  /// The [Logger] for this
  static final Logger log = new Logger("DcmReader", watermark: Severity.config);

  /// The [ByteData] being read.
  final ByteData bd;

  /// The [RootDataset] being created by [this].
  final RootDataset _rootDS;

  /// The source of the [Uint8List] being read.
  final String path;
  final bool fmiOnly;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// If [true] and [FMI] is not present, abort reading.
  final bool allowMissingFMI;

  /// The expected [TransferSyntax] of [bd].
  final TransferSyntax targetTS;

  /// The index where reading should stop.
  final int endOfBD;

  /// The current dataset.  This changes as Sequences are read.
  Dataset _currentDS;

  /// The current read index.
  int _rIndex = 0;
  bool get _isReadable => _rIndex < endOfBD;

  // ParseInfo values
  bool _wasShortFile = false;
  bool _preambleWasZeros;
  bool _hadPrefix = false;
  bool _hadParsingErrors = false;
  bool _hadTrailingBytes = false;
  bool _hadTrailingZeros = false;
  bool _hadNonZeroDelimiterLength = false;
  int _pixelDataStart;
  int _pixelDataEnd;
  int _endOfLastElement;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReader(this.bd, this._rootDS,
      {this.path = "",
      this.fmiOnly = false,
      this.throwOnError = true,
      this.allowMissingFMI = false,
      this.targetTS})
      : endOfBD = bd.lengthInBytes,
        _wasShortFile = bd.lengthInBytes < shortFileThreshold {
    _warnIfShortFile();
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory DcmReader.fromList(List<int> list, RootDataset rootDS,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new DcmReader(bd, rootDS,
        path: path,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS);
  }

/* Flush if not needed
  DcmReader._(this.bd, this.path, this.fmiOnly, this.throwOnError, this.allowMissingFMI,
      this.targetTS, this.rootDS)
      : endOfBD = bd.lengthInBytes {
    _warnIfShortFile();
  }
*/

  /// External interface for testing.
  bool get isReadable => _isReadable;

  /// External interface for testing.
  RootDataset get rootDS => _rootDS;

  /// External interface for testing.
  RootDataset get currentDS => _currentDS;

  String get info => '$runtimeType: rootDS: ${_rootDS.info}, currentDS: ${_currentDS.info}';

  bool readFMI([bool checkPreamble = false]) {
    bool _hadFmi = _readFMI(checkPreamble);
    _rootDS.parseInfo = new ParseInfo(
        path,
        bd.lengthInBytes,
        shortFileThreshold,
        _wasShortFile,
        _preambleWasZeros,
        _hadPrefix,
        _hadFmi,
        _hadParsingErrors,
        _hadTrailingBytes,
        _hadTrailingZeros,
        _hadNonZeroDelimiterLength,
        _pixelDataStart,
        _pixelDataEnd,
        _endOfLastElement);
    return _hadFmi;
  }

  /// Reads a [RootDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootDataset readRootDataset({bool allowMissingFMI = false}) {
    _currentDS = _rootDS;
    var ds = readFMI();
    if (ds == null) return null;
    assert(ds == _rootDS);

    //TODO: move TS processing to separate loop - maybe in dataset
    log.debug('$rmm tsString: "${_rootDS.transferSyntaxString}"');
    log.debug('$rmm ${_rootDS.transferSyntax}');
    if (!allowMissingFMI && !_rootDS.hasFMI) return null;

    log.debug('$rbb targetTS: $targetTS');
    TransferSyntax ts = _rootDS.transferSyntax;
    if (targetTS != null && ts != targetTS) return _rootDS;

    log.debug('$rmm readRootDataset: TS($ts)}, isExplicitVR: $ds.isEVR');
    if (!_rootDS.hasValidTransferSyntax) {
      _hadParsingErrors = true;
      if (throwOnError) throw new InvalidTransferSyntaxError(ts);
      return _rootDS;
    }
    if (ts == TransferSyntax.kExplicitVRBigEndian) {
      _hadParsingErrors = true;
      if (throwOnError) throw new InvalidTransferSyntaxError(ts);
      return _rootDS;
    }
    _readDataset(_rootDS);
    log.debug('$ree readRootDataset: ${_rootDS.info}');
    return _rootDS;
  }

  /// External Interface for testing.
  Element readElement([bool isEVR = true]) => _readElement(isEVR);

  String toString() => '$runtimeType: rootDS: $_rootDS, currentDS: $_currentDS';

  /// Reads only the File Meta Information ([FMI], if present.
  static RootDataset readBytes(Uint8List bytes, Dataset rootDS,
      {String path = "", bool fmiOnly = false, TransferSyntax targetTS}) {
    ByteData bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, rootDS, path: path, fmiOnly: fmiOnly, targetTS: targetTS);
    return reader.readRootDataset();
  }

/* Flush if not needed
  static RootDataset readBytes(Uint8List bytes,
          {String path: "", bool fmiOnly = false, TransferSyntax targetTS}) =>
      DcmReader.rootDataset(bytes, path: path, fmiOnly: fmiOnly, targetTS: targetTS);
*/

  static RootDataset readFile(File file, RootDataset rootDS,
      {bool fmiOnly = false, TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes, rootDS, path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  /// Reads only the File Meta Information ([FMI], if present.
  static RootDataset readFileFmiOnly(File file, RootDataset rootDS,
      {String path = "", TransferSyntax targetTS}) =>
      readFile(file, rootDS, fmiOnly: true, targetTS: targetTS);

  // **** Internal Methods
  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
  bool _readPrefix(bool checkPreamble) {
    Uint8List readChars(int length) {
      var chars = bd.buffer.asUint8List(_rIndex, length);
      _rIndex += length;
      return chars;
    }

    String readAsciiString(int length) => ASCII.decode(readChars(length));

    if (_rIndex != 0) {
      log.error('Attempt to read DICOM Prefix at ByteData[$_rIndex]');
      return false;
    }
    if (_hadPrefix != null) {
      log.error('Attempt to re-read DICOM Preamble and Prefix.');
      return false;
    }
    if (checkPreamble) {
      _preambleWasZeros = true;
      for (int i = 0; i < 128; i++) if (bd.getUint8(i) != 0) _preambleWasZeros = false;
    } else {
      _skip(128);
    }
    final String prefix = readAsciiString(4);
    bool v = (prefix == "DICM") ? true : false;
    _hadPrefix = v;
    if (v == false) {
      log.warn('_hasPrefix: No DICOM Prefix present');
      _skip(-132);
    }
    return v;
  }

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  bool _readFMI(checkPreamble) {
    _currentDS = _rootDS;
    log.debugDown('$rbb readFmi($_currentDS)');
    if (_hadPrefix == null) _readPrefix(checkPreamble);
    log.debug2('$rmm readFMI: prefix($_hadPrefix) $_rootDS');
    if (!_hadPrefix) return null;
    int start = _rIndex; //TODO: test this
    int code;
    try {
      while (_isReadable) {
        log.debugDown('$rbb readFMI loop:');
        code = _peekTagCode();
        if (code >= 0x00080000) {
          break;
        } else if (code == 0) {
          _zeroEncountered(code);
          return _rootDS.length > 0;
        } else {
          Element e = _readElement(true);
          _rootDS.add(e);
          log.debugUp('$ree readFMI loop: $e');
        }
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hadParsingErrors = true;
      log.debugUp('$ree readFMI TS catch: $x');
      rethrow;
    } catch (x) {
      if (code == 0) _zeroEncountered(code);
      _hadParsingErrors = true;
      log.error('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = start;
      rethrow;
    }
    log.debugUp('$ree readFmi: ${_rootDS.transferSyntax}\n   ${_rootDS.info}');
    return true;
  }

  void _readDataset(Dataset ds) {
    assert(_currentDS != null);
    log.debug('$rbb readDataset: isExplicitVR(${ds.isEVR})');
    while (_isReadable) {
      Element e = _readElement(ds.isEVR);
      _currentDS.add(e);
    }
    log.debug('$ree end readDataset: isExplicitVR(${ds.isEVR})');
  }

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => _hadPrefix != null;

  /// [true] if the source contained a DICOM Preamble and Prefix.
//  bool get hadPrefix => rootDS.hadPrefix;

  /// [true] if the source contained DICOM File Meta Information (FMI).
  //bool get hasFMI => _hadFMI;

  /// [true] if the source of this [RootDataset] had trailing zeros following
  /// the last [Element] of the [Dataset].
  // bool get hadTrailingZeros => rootDS.hadTrailingZeros;

  // **** DICOM encoding stuff ****

  Element _readElement(bool isEVR) {
    int code = _readTagCode();
    // Sometimes there are zeros at the end of the file
    if (code == 0) _zeroEncountered(code);
    return (isEVR) ? _readEVR(code) : _readIVR(code);
  }

  Element _readEVR(int code) {
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

  ByteData _getElementBD(int start, int eLength) {
    int endOfVF = start + eLength;
    if (endOfVF > endOfBD)
      log.error('$rmm endOfVR($endOfVF) is beyond the end of File: $path\n'
          '    start($start) + eLength($eLength) = $endOfVF > $endOfBD');
    return bd.buffer.asByteData(start, eLength);
  }

  Element _readIVR(int code) {
    bool isSequence() {
      int code = _peekTagCode();
      if (code == kItem || code == kSequenceDelimitationItem) {
        _skip(-4);
        return true;
      }
      return false;
    }

    int start = _rIndex - 4; // for code
    int vfLength = _readUint32();
    if (isSequence()) return _readSequence(code, 8, false);
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

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads an EVR or IVR Sequence. The _readElementMethod detects Sequences.
  Element _readSequence(int code, int headerLength, bool isEVR) {
    /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
    bool checkForSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem);

    int vfLength = _readUint32();
    int start = _rIndex - headerLength;
    var hadUndefinedLength = (vfLength == kUndefinedLength);
    //  log.debugDown('$rbb SQ${toDcm(code)} start($start) undefinedLength'
    //      '($hadUndefinedLength), vfLength(${toHex32(vfLength)}, $vfLength)');
    int endOfVF;
    List<Dataset> items = <Dataset>[];
    if (hadUndefinedLength) {
      //    log.debug1('$rmm SQ${toDcm(code)} Undefined Length');
      while (!checkForSequenceDelimiter()) items.add(_readItem(isEVR));
      endOfVF = _rIndex;
      //    log.debug1('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
      //    log.debug1('$rmm SQ: ${toDcm(code)} vfLength($vfLength)');
      endOfVF = start + headerLength + vfLength;
      while (_rIndex < endOfVF) items.add(_readItem(isEVR));
      //     log.debug1('$rmm SQ Length($vfLength) start($start) endOfVF($endOfVF)');
    }
    var e = bd.buffer.asByteData(start, endOfVF - start);
    var sq;
    //TODO: should be able to fix the type issue
    if (isEVR) {
      sq = new EVRSequence(e, _currentDS, items, hadUndefinedLength);
    } else {
      sq = new IVRSequence(e, _currentDS, items, hadUndefinedLength);
    }
    for (Dataset item in items) item.addSQ(sq);
    //  log.debugUp('$ree $sq');
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [Item] or Fragment.
  Dataset _readItem(isExplicitVR) {
    /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
    bool checkForItemDelimiter() => _checkForDelimiter(kItemDelimitationItem);

    int start = _rIndex;
    int code = _readTagCode();
    //   log.debug('$rbb item kItem(${toHex32(kItem)}, code ${toHex32(code)}');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
    int vfLength = _readUint32();
    //  log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    Dataset parentDS = _currentDS;
    Map<int, Element> elements = <int, Element>{};
    bool hadUndefinedLength = vfLength == kUndefinedLength;
    //  log.debug1('$rmm readItem hadUndefinedLength=$hadUndefinedLength');
    int endOfVF;
    try {
      if (hadUndefinedLength) {
        while (!checkForItemDelimiter()) {
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
    } on EndOfDataError {
      //    log.debug1('_readItem end of data exception: @$_rIndex');
      rethrow;
    } catch (e) {
      _hadParsingErrors = true;
      log.error(e);
      rethrow;
    } finally {
      // Restore previous parent
      _currentDS = parentDS;
    }

    var e = bd.buffer.asByteData(start, endOfVF - start);
    var item = new Dataset(e, parentDS, elements, hadUndefinedLength);
    //  log.debug('$ree readItemElements: ${item.length} Items');
    return item;
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
    _hadNonZeroDelimiterLength = true;
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
      int delimiterLength = _readUint32();
      if (delimiterLength != 0) _delimiterLengthFieldWarning(delimiterLength);
      int endOfVF = _rIndex - 8;
      return endOfVF;
    }
    _hadParsingErrors = true;
    throw "vfLength($vfLength) not kUndefinedLength";
  }

  /*
  /// Reads
  int _readTagCode() {
    int group = bd.getUint16(_rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(_rIndex + 2, Endianness.HOST_ENDIAN);
    _rIndex += 4;
    return (group << 16) + elt;
  }
*/

  /// Reads a group and element and combines them into a Tag.code.
  int _readTagCode() {
    int code = _peekTagCode();
    _rIndex += 4;
    return code;
  }

  /// Peek at next tag - doesn't move the [_rIndex].
  int _peekTagCode() {
    int group = bd.getUint16(_rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(_rIndex + 2, Endianness.HOST_ENDIAN);
    return (group << 16) + elt;
  }

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

//  String _readUtf8String(int length) => UTF8.decode(_readChars(length));

  void _warnIfShortFile() {
    if (_wasShortFile) {
      var s = 'Short file error: length(${bd.lengthInBytes}) $path';
      log.warn('**** $s');
      if (throwOnError) throw s;
    }
  }
  // **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _rrr => 'R@$_rIndex';

  /// The beginning of reading an [Element] or [Item].
  String get rbb => '> $_rrr';

  /// In the middle of reading an [Element] or [Item]
  String get rmm => '| $_rrr';

  /// The end of reading an [Element] or [Item]
  String get ree => '< $_rrr';

/* Flush if not needed
 /// Reads only the File Meta Information ([FMI], if present.
  static RootDataset xReadDataset(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
    bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.xReadDataset();
  }*/

  /// Returns [true] if there are only trailing zeros at the end of the
  /// Object being parsed.
  bool _zeroEncountered(int code) {
    int mark = _rIndex - 4;
    log.warn('$rmm Zero code($code) encountered @$mark');
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
        _hadParsingErrors = true;
        if (throwOnError) throw "bad code ${toDcm(code)}";
        return false;
      }
    }
    _hadTrailingZeros = true;
    log.warn('returning from reading zeros from @$mark to @$_rIndex in "$path"');
    return true;
  }
}
