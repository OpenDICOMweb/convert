// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dictionary/dictionary.dart';

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
abstract class DcmReader {
  static const int shortFileThreshold = 1024;
  //TODO: remove log.debug when working
  /// The [Logger] for this
  static final Logger log = new Logger("DcmReader", watermark: Severity.debug2);

  /// The [ByteData] being read.
  final ByteData bd;

  /// The source of the [Uint8List] being read.
  final String path;
  final bool fmiOnly;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// If [true] and [FMI] is not present, abort reading.
  final bool allowMissingFMI;

  /// The expected [TransferSyntax] of [bd].
  final TransferSyntax targetTS;

  final bool reUseBD;

  /// The index where reading should stop.
  final int endOfBD;

  final List<int> elementIndex = new List<int>(1000);
  int nthElement = 0;

  /// The current read index.
  int _rIndex = 0;
  bool get _isReadable => _rIndex < endOfBD;

  // ParseInfo values
  int _nElements = 0;
  int _nTopLevelElements = 0;
  int _nSequences = 0;
  int _nPrivateElements = 0;
  int _nPrivateSequences = 0;
  bool _wasShortFile = false;
  bool _preambleWasZeros;
  Uint8List _preamble;
  bool _hadPrefix;
  bool _hadGroupLengths = false;
  bool _hadFmi = false;
  TransferSyntax _ts;
  bool _hadParsingErrors = false;
  bool _hadTrailingBytes = false;
  bool _hadTrailingZeros = false;
  int _nonZeroDelimiterLengths = 0;
  int _pixelDataStart;
  int _pixelDataEnd;
  int _endOfLastElement;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReader(this.bd,
      {this.path = "",
      this.fmiOnly = false,
      this.throwOnError = true,
      this.allowMissingFMI = false,
      this.targetTS,
      this.reUseBD = true})
      : endOfBD = bd.lengthInBytes,
        _wasShortFile = bd.lengthInBytes < shortFileThreshold {
    _warnIfShortFile();
  }

  Dataset get rootDS;

  /// External interface for testing.
  bool get isReadable => _isReadable;

  /// The current dataset.  This changes as Sequences are read.
  Dataset get currentDS;
  void set currentDS(Dataset ds);

  Element makeElement(int code, int vrCode, [List values, bool isEVR = true]);

  Element makeElementFromBytes(int code, int vrCode, int vfOffset,
      Uint8List vfBytes, int vfLength, bool isEVR,
      [VFFragments fragments]);

  Element makeElementFromByteData(ByteData bd, bool isEVR);

  Dataset makeItem(ByteData bd, Dataset parent, Map<int, Element> elements,
      int vfLength, bool hadULength,
      [Element sq]);

  Element makeSequence(int code, List items, ByteData vf, bool hadULength,
      [bool isEVR = true]);

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  ParseInfo _parseInfo;
  ParseInfo get parseInfo => _parseInfo ??= getParseInfo();

  ParseInfo getParseInfo() => new ParseInfo(
      path,
      _nElements,
      _nTopLevelElements,
      _nSequences,
      _nPrivateElements,
      _nPrivateSequences,
      shortFileThreshold,
      _wasShortFile,
      _preambleWasZeros,
      _preamble,
      _hadPrefix,
      _hadFmi,
      _hadGroupLengths,
      _ts,
      _hadParsingErrors,
      _hadTrailingBytes,
      _hadTrailingZeros,
      _nonZeroDelimiterLengths,
      bd.lengthInBytes,
      _pixelDataStart,
      _pixelDataEnd,
      _endOfLastElement);

  bool dcmReadFMI([bool checkPreamble = false]) => _readFMI(checkPreamble);

  /// Reads a [RootDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  Dataset readRootDataset({bool allowMissingFMI = false}) {
    log.debug('$rbb readRootDataset');
    currentDS = rootDS;
    _hadFmi = _readFMI(true);
    if (!allowMissingFMI && !_hadFmi) return null;

    log.debug('$rmm targetTS: $targetTS');
    TransferSyntax ts =
        (_hadFmi) ? rootDS.transferSyntax : System.defaultTransferSyntax;
    if (targetTS != null && ts != targetTS) return rootDS;

    log.debug('$rmm readRootDataset: TS($ts)}, isExplicitVR: ${rootDS.isEVR}');
    if (!System.isSupportedTransferSyntax(ts)) {
      _hadParsingErrors = true;
      log.debug('$ree readRootDataset: Unsupported TS: $ts');
      if (throwOnError) throw new InvalidTransferSyntaxError(ts);
      return rootDS;
    }
    _readDataset(rootDS);

    _nTopLevelElements = rootDS.length;
    _parseInfo = getParseInfo();
    log.debug('$rmm nTopLevelElements: ${rootDS.length}');
    log.debug('$ree readRootDataset: ${rootDS.info}');
    log.debug('elementIndex: length($nthElement)');
    return rootDS;
  }

  /// External Interface for testing.
  Element readElement([bool isEVR = true]) => _readElement(isEVR);

  String toString() => '$runtimeType: rootDS: $rootDS, currentDS: $currentDS';

  // **** Internal Methods
  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
  bool _readPrefix(bool checkPreamble) {
    String readAsciiPrefix() {
      var chars = bd.buffer.asUint8List(_rIndex, 4);
      _rIndex += 4;
      return ASCII.decode(chars);
    }

    String msg = "";
    if (_rIndex != 0)
      msg += 'Attempt to read DICOM Prefix at ByteData[$_rIndex]\n';
    if (_hadPrefix != null)
      msg += 'Attempt to re-read DICOM Preamble and Prefix.\n';
    if (endOfBD <= 132) msg += 'ByteData length($endOfBD) < 132';
    if (msg.length > 0) {
      log.error(msg);
      return false;
    }
    if (checkPreamble) {
      _preambleWasZeros = true;
      _preamble = bd.buffer.asUint8List(0, 128);
      for (int i = 0; i < 128; i++)
        if (bd.getUint8(i) != 0) _preambleWasZeros = false;
    }
    _skip(128);

    final String prefix = readAsciiPrefix();
    bool v = (prefix == "DICM") ? true : false;
    _hadPrefix = v;
    if (v == false) {
      log.warn('hasPrefix: No DICOM Prefix present');
      _skip(-132);
    }
    return v;
  }

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  bool _readFMI(checkPreamble) {
    currentDS = rootDS;
    log.debugDown('$rbb readFmi($currentDS)');
    if (_hadPrefix == null) _readPrefix(checkPreamble);
    log.debug1('$rmm readFMI: prefix($_hadPrefix) $rootDS');
    if (!_hadPrefix) return null;
    int start = _rIndex; //TODO: test this
    int code;
    try {
      while (_isReadable) {
        code = _peekTagCode();
        if (code >= 0x00030000) {
          log.debug('$rmm: end of FMI');
          break;
        } else if (code == 0) {
          _zeroEncountered(code);
          log.debug('$rmm Zero encountered');
          return rootDS.length > 0;
        } else {
          Element e = _readElement(true);
          rootDS.add(e);
          log.debug('$rmm $e');
        }
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hadParsingErrors = true;
      log.warn('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = 0;
      log.debugUp('$ree readFMI Invalid TS catch: $x');
      rethrow;
    } catch (x) {
      if (code == 0) _zeroEncountered(code);
      _hadParsingErrors = true;
      log.error('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = start;
      log.debugUp('$ree readFMI Catch: $x');
      rethrow;
    }
    _ts = rootDS.transferSyntax;
    log.debug('$rmm TS:${_ts}');
    log.debugUp('$ree readFmi: ${_ts}   ${rootDS.info}');
    return true;
  }

  void _readDataset(Dataset ds) {
    assert(currentDS != null);
    log.debugDown('$rbb readDataset: isExplicitVR(${ds.isEVR})');
    while (_isReadable) {
      Element e = _readElement(ds.isEVR);
      currentDS.add(e);
    }
    log.debugUp('$ree end readDataset: isExplicitVR(${ds.isEVR})');
  }

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => _hadPrefix != null;

  Element _readElement(bool isEVR) {
    elementIndex[nthElement] = _rIndex;
    nthElement++;

    int code = _readTagCode();
    // Sometimes there are zeros at the end of the file
    if (code == 0) _zeroEncountered(code);
    if (code == kPixelData) _pixelDataStart = _rIndex;
    Element e = (isEVR) ? _readEVR(code) : _readIVR(code);
    // Statistics
    _nElements++;
    if (Tag.isPrivateCode(code)) _nPrivateElements++;
    //Urgent add to dict isGroupLength
    if ((code & 0xFFFF) == 0) _hadGroupLengths = true;
    if (code == kPixelData) _pixelDataEnd = _rIndex;
    _endOfLastElement = _rIndex;
    return e;
  }

  Element _readEVR(int code) {
    int eStart = _rIndex - 4; // for code
    int vrCode = _readUint16();
    VR vr = VR.lookup(vrCode);
    assert(vr != null, 'Invalid null VR: vrCode(${toHex16(vrCode)})');
    if (vrCode == kSQCode) {
      _skip(2);
      return _readSequence(code, 12, true);
    }

    log.debugDown('$rbb _readEVR: start($eStart), ${toDcm(code)} $vr');
    int eLength;
    if (vr.hasShortVF) {
      eLength = 8 + _readUint16();
      _rIndex = eStart + eLength;
    } else {
      _skip(2);
      int vfLength = _readUint32();
      if (vfLength == kUndefinedLength) {
        int endOfVF = _findEndOfVF(vfLength);
        eLength = endOfVF - eStart;
        _rIndex = endOfVF + 8;
      } else {
        eLength = 12 + vfLength;
        _rIndex = eStart + eLength;
      }
    }
    var e = _makeElement(eStart, eLength, isEVR: true);
/* FLush when working
   ByteData bdx = _getElementBD(eStart, eLength);
    var e = new EVRElement.fromByteData(bdx);*/
    log.debugUp('$ree _readEVR: $e');
    return e;
  }

  Element _makeElement(int eStart, int eLength, {bool isEVR: true}) {
    int endOfVF = eStart + eLength;
    if (endOfVF > endOfBD)
      log.error('$rmm endOfVR($endOfVF) is beyond the end of File: $path\n'
          '    start($eStart) + eLength($eLength) = $endOfVF > $endOfBD');
    var e = bd.buffer.asByteData(eStart, eLength);
    return makeElementFromByteData(e, isEVR);
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

    int eStart = _rIndex - 4; // for code
    int vfLength = _readUint32();
    if (isSequence()) return _readSequence(code, 8, false);

    log.debugDown('$rbb _readIVR: ${toDcm(code)} start($eStart), '
        'vfL($vfLength), endOfVF(${eStart + vfLength}');
    int eLength;
    if (vfLength == kUndefinedLength) {
      int endOfVF = _findEndOfVF(vfLength);
      eLength = endOfVF - eStart;
      _rIndex = endOfVF + 8;
    } else {
      eLength = 8 + vfLength;
      _rIndex = eStart + eLength;
    }
    var e = _makeElement(eStart, eLength, isEVR: false);
/* FLush when working
    ByteData bdx = _getElementBD(eStart, eLength);
    var e = new IVRElement.fromByteData(bdx);*/
    log.debugUp('$ree _readIVR: $e');
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
    bool checkForSequenceDelimiter() =>
        _checkForDelimiter(kSequenceDelimitationItem);

    log.debugDown('$rbb readSQ ${toDcm(code)}');
    int vfLength = _readUint32();
    int vfStart = _rIndex;
//    int start = _rIndex - headerLength;
    var hadULength = (vfLength == kUndefinedLength);
    int endOfVF;
    // Note: this is a list of Items.
    // FIX: give this a type when understood.
    List items = [];
    if (hadULength) {
      //    log.debug1('$rmm SQ${toDcm(code)} Undefined Length');
      while (!checkForSequenceDelimiter()) items.add(_readItem(isEVR));
      endOfVF = _rIndex;
      //    log.debug1('$rmm SQ Undefined Length: start($start) endOfVF($endOfVF)');
    } else {
      //    log.debug1('$rmm SQ: ${toDcm(code)} vfLength($vfLength)');
      endOfVF = vfStart + vfLength;
      while (_rIndex < endOfVF) items.add(_readItem(isEVR));
      //log.debug1('$rmm SQ Length($vfLength) start($start) endOfVF($endOfVF)');
    }
//    var e = bd.buffer.asByteData(start, endOfVF - start);
    var vfBD = bd.buffer.asByteData(vfStart, endOfVF);
    Element sq = makeSequence(code, items, vfBD, hadULength, isEVR);
    _nSequences++;
    if (Tag.isPrivateCode(code)) _nPrivateSequences++;
    log.debugUp('$ree readSQ $sq ${sq.values.length} items');
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
    log.debugDown('$rbb item kItem(${toHex32(kItem)}, code ${toHex32(code)}');
    assert(code == kItem, 'Invalid Item code: ${toDcm(code)}');
    int vfLength = _readUint32();
    //  log.debug('$rmm item vfLength(${toHex32(vfLength)}, $vfLength)');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    Dataset parentDS = currentDS;
    Map<int, Element> elements = <int, Element>{};
    bool hadULength = vfLength == kUndefinedLength;
    //  log.debug1('$rmm readItem hadUndefinedLength=$hadUndefinedLength');
    int endOfVF;
    try {
      if (hadULength) {
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
      log.debugUp('_readItem end of data exception: @$_rIndex');
      rethrow;
    } catch (e) {
      _hadParsingErrors = true;
      log.error(e);
      log.up;
      rethrow;
    } finally {
      // Restore previous parent
      currentDS = parentDS;
    }
    var itemBD = bd.buffer.asByteData(start, endOfVF - start);
    var item = makeItem(itemBD, currentDS, elements, vfLength, hadULength);
    log.debugUp('$ree readItemElements: ${item.length} Elements');
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
    _nonZeroDelimiterLengths++;
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
    log.warn(
        'returning from reading zeros from @$mark to @$_rIndex in "$path"');
    return true;
  }
}
