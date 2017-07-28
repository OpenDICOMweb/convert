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
import 'package:dcm_convert/src/dcm/element_list.dart';
import 'package:dictionary/dictionary.dart';

//TODO: redoc to reflect current state of code

/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
typedef Element ElementMaker<V>(ByteData bd);

typedef Element SequenceMaker<V>(
    ByteData bd, Dataset parent, List<Dataset> items);

typedef Element PixelDataMaker<V>(
    ByteData bd, Dataset parent, List<Dataset> items);

/// A [Converter] [Uint8List]s containing a [Dataset] encoded in the
/// application/dicom media type.

/// _Notes_:
/// 1. Reads and returns the Value Fields as they are in the data.
///  For example DcmReader does not trim whitespace from strings.
///  This is so they can be written out byte for byte as they were
///  read. and a byte-wise comparator will find them to be equal.
/// 2. All String manipulation should be handled by the containing
///  [Element] itself.
/// 3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
abstract class DcmReader {
  static const int shortFileThreshold = 1024;
  //TODO: remove log.debug when working
  /// The [Logger] for this
  static final Logger log = new Logger("DcmReader", watermark: Severity.info);

  /// The [ByteData] being read.
  final ByteData bd;

  // Input parameters
  final bool async;
  final bool fast;
  final bool fmiOnly;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// If [true] and [FMI] is not present, abort reading.
  final bool allowMissingFMI;

  /// If [true], then duplicate [Element]s will be stored.
  final bool allowDuplicates;

  /// The expected [TransferSyntax] of [bd].
  final TransferSyntax targetTS;

  //TODO: make this a constructor argument
  final bool doCheckVR = true;

  /// If [true] elements with VR.kUN will be converted to correct VR if known.
  final bool doConvertUndefinedVR;

  /// If [true] the [ByteData] buffer ([bd] will be reused.
  final bool reUseBD;

  // **** stats and debugging
  final bool statisticsEnabled = true;
  final bool elementListEnabled = true;
  final ElementList elementList = new ElementList();

  // ParseInfo values
  bool _isEVR;
  int _nElementsRead = 0;
  int _nSequences = 0;
  int _nDSequences = 0;
  int _nUSequences = 0;
  int _nPrivateElements = 0;
  int _nPrivateSequences = 0;

  /// The source of the [Uint8List] being read.
  final String path;
  bool _hadFmi = false;
  Uint8List _preamble;
  bool _preambleWasZeros;
  bool _hadPrefix;
  bool _hadGroupLengths = false;
  bool _hadParsingErrors = false;
  int _nonZeroDelimiterLengths = 0;
  int _nOddLengthValueFields = 0;

  TransferSyntax _ts;
  VR _pixelDataVR;
  int _pixelDataStart;
  int _pixelDataEnd;
  int _lastElementCode;
  Element _lastElement;
  int _endOfLastValueRead;
  bool _beyondPixelData = false;

  /// The index where the last element in the root [Dataset] ended.
  int _dsLengthInBytes;

  /// The length of the [ByteData] being read.
  final int _bdLength;
  bool _wasShortFile = false;
  bool _hadTrailingBytes = false;
  bool _hadTrailingZeros = false;

  /// The current read index.
  int _rIndex = 0;

  // *** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReader(this.bd,
      {this.path = "",
      this.async = true,
      this.fast: true,
      this.fmiOnly = false,
      this.throwOnError = true,
      this.allowMissingFMI = false,
      this.allowDuplicates = true,
      this.targetTS,
      this.doConvertUndefinedVR = false,
      this.reUseBD = true})
      : _bdLength = bd.lengthInBytes,
        _wasShortFile = bd.lengthInBytes < shortFileThreshold {
    log.debug('ByteData length: $_bdLength');
    _warnIfShortFile();
  }

  bool get isEVR => _isEVR;

  Dataset get rootDS;

  bool get _isReadable => _rIndex < _bdLength;

  /// External interface for testing.
  bool get isReadable => _isReadable;

  bool _hasRemaining(int n) => (_rIndex + n) <= _bdLength;

  bool hasRemaining(int n) => _hasRemaining(n);

  /// The current dataset.  This changes as Sequences are read.
  Dataset get currentDS;
  void set currentDS(Dataset ds);

  Map<int, Element> currentMap;
  Map<int, Element> currentDupMap;
  Uint8List get bytes =>
      bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);

  /// Interface to Item constructor.
  Dataset makeItem(
      ByteData bd, Dataset parent, int vfLength, Map<int, Element> map,
      [Map<int, Element> dupMap]);

  /// Interface to Sequence constructor.
  Element makeSequence(ByteData bd, List items, int vfLength, bool isEVR);

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  ParseInfo getParseInfo() {
    return new ParseInfo(
        _isEVR,
        _nElementsRead,
        _nSequences,
        _nPrivateElements,
        _nPrivateSequences,
        rootDS.total,
        rootDS.length,
        rootDS.duplicates.length,
        0,
        0,
        0,
        path,
        _hadFmi,
        _preamble,
        _preambleWasZeros,
        _hadPrefix,
        _hadGroupLengths,
        _hadParsingErrors,
        _nonZeroDelimiterLengths,
        _nOddLengthValueFields,
        _ts,
        _pixelDataVR,
        _pixelDataStart,
        _pixelDataEnd,
        _lastElement,
        _lastElementCode,
        _endOfLastValueRead,
        _dsLengthInBytes,
        _bdLength,
        shortFileThreshold,
        _wasShortFile,
        _hadTrailingBytes,
        _hadTrailingZeros);
  }

  bool dcmReadFMI([bool checkPreamble = false]) {
    currentDS = rootDS;
    currentMap = rootDS.map;
    currentDupMap = rootDS.dupMap;
    return _readFMI(checkPreamble);
  }

  /// Reads a Root [Dataset] from [this] and returns it.
  /// If an error is encountered and [throwOnError] is [true],
  /// an Error will be thrown; otherwise, returns [null].
  Dataset dcmReadRootDataset({bool allowMissingFMI = false}) {
    log.debug('$rbb readRootDataset');
    currentDS = rootDS;
    currentMap = rootDS.map;
    currentDupMap = rootDS.dupMap;
    _readFMI(true);
    if (!allowMissingFMI && !_hadFmi) return null;
    if (targetTS != null && _ts != targetTS) return rootDS;

    if (!System.isSupportedTransferSyntax(_ts)) {
      _hadParsingErrors = true;
      log.debug('$ree Unsupported TS: $_ts @end');
      if (throwOnError) throw new InvalidTransferSyntaxError(_ts);
      return rootDS;
    }

    Element e;
    log.debug('$rmm _isEVR: $_isEVR');
    try {
      e = _readDataset(rootDS);
    } on EndOfDataError {
      log.info('$_rrr EndOfDataError');
      _dsLengthInBytes = _endOfLastValueRead;
      return rootDS;
    } on ShortFileError {
      rethrow;
    } on RangeError catch (ex) {
      log.error('$ex');
      //    _showNext(_rIndex);
      log.error('$_rrr endOfLastValueRead: $_endOfLastValueRead');
      log.error('last value read: ${toDcm(_lastElementCode)}');
      log.error('last element read: $e');
      _dsLengthInBytes = _endOfLastValueRead;
      if (_beyondPixelData) log.info('$_rrr Beyond Pixel Data');
      // Keep: *** Keep, but only use for debugging.
      if (throwOnError) rethrow;
      return rootDS;
    } catch (ex) {
      log.error('$ex');
      log.error('$_rrr endOfLastValueRead: $_endOfLastValueRead');
      if (_beyondPixelData) return rootDS;
      _dsLengthInBytes = _endOfLastValueRead;
      // *** Keep, but only use for debugging.
      if (throwOnError) rethrow;
    }

    _dsLengthInBytes = _endOfLastValueRead;
    log.debug('$rmm lastElementRead: $_lastElement');
    log.debug('$rmm lastElementCode: ${toDcm(_lastElementCode)}');
    log.debug('$rmm dsLengthInBytes: $_dsLengthInBytes');
    log.debug('$rmm nTopLevelElements: ${rootDS.length}');
    log.debug('$rmm _nSequences: $_nSequences');
    log.debug('$rmm _nDSequences: $_nDSequences');
    log.debug('$rmm _nDSequences: $_nUSequences');
    log.debug('$rmm _nDSequences: $_nPrivateSequences');
    log.debug('$rmm nTotalElements: ${rootDS.total}');
    log.debug('$ree ${rootDS.info}');

    if (_rIndex != _bdLength) {
      log.warn('$_rrr end with _rIndex($_rIndex) != _bdLength($_bdLength)');
      _dsLengthInBytes = _rIndex;
      _endOfLastValueRead = _rIndex;
      _hadTrailingBytes = true;
      _hadTrailingZeros = _checkAllZeros(_rIndex, _bdLength);
    }

    if (_nElementsRead != (rootDS.total + rootDS.dupTotal)) {
      var msg = '** Inconsistent Elements Error: '
          '_nElementsRead($_nElementsRead), rootDS(${rootDS.total})';
      log.error(msg);
      if (throwOnError) throw msg;
    }
    _rootDSStats();
    return rootDS;
  }

/* Flush if not needed by V0.9.0
 /// Reads only the File Meta Information ([FMI], if present.
  static RootDataset xReadDataset(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
    bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.xReadDataset();
  }*/

  /// External Interface for testing.
  Element readElement() => _readElement();

  String toString() => '$runtimeType: rootDS: $rootDS, currentDS: $currentDS';

  // **** Internal Methods
  /// Reads the Preamble (128 bytes) and Prefix ('DICM')
  /// of a PS3.10 DICOM File Format.
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
    if (_bdLength <= 132) msg += 'ByteData length($_bdLength) < 132';
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
      log.warn('** No DICOM Prefix present');
      _skip(-132);
    }
    return v;
  }

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  bool _readFMI(checkPreamble) {
    _isEVR = true;
    assert(currentDS == rootDS);
    log.debugDown('$rbb readFmi($currentDS)');
    if (_hadPrefix == null) _readPrefix(checkPreamble);
    log.debug1('$rmm readFMI: prefix($_hadPrefix) $rootDS');
    if (!_hadPrefix) {
      log.debugUp('$ree  No Prefix');
      return null;
    }
    int eStart = _rIndex;
    int code;
    try {
      while (_isReadable) {
        code = _peekTagCode();
        log.debug2('$rmm code(${toDcm(code)}');
        if (code >= 0x00030000) {
          log.debug('$rmm   End of FMI');
          break;
        } else if (code == 0) {
          _zeroEncountered(code);
          log.debugUp('$ree Zero encountered');
          return rootDS.length > 0;
        } else {
          Element e = _readElement();
          log.debug2('$rmm $e');
        }
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hadParsingErrors = true;
      log.warn('Failed to read FMI: "$path"\nException: $x\n');
      log.warn('  File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = 0;
      log.debugUp('$ree readFMI Invalid TS catch: $x');
      rethrow;
    } catch (x) {
      if (code == 0) _zeroEncountered(code);
      _hadParsingErrors = true;
      log.error('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = eStart;
      log.debugUp('$ree readFMI Catch: $x');
      rethrow;
    }
    if (!isReadable) throw new EndOfDataError('_readFMI');
    _hadFmi = true;
    log.debug2('$rmm hadFMI: $_hadFmi');
    _ts = rootDS.transferSyntax;
    if (_ts == null) _ts = System.defaultTransferSyntax;
    _isEVR = !_ts.isImplicitLittleEndian;

    log.debug1('$rmm isExplicitVR: $_isEVR');
    log.debug('$rmm TS:${_ts}');
    log.debug1('$rmm targetTS: $targetTS');
    log.debugUp('$ree readFmi: ${rootDS.info}');
    return true;
  }

  //TODO: move to dcmReadRootDataset
  /// Reads a [Dataset] and returns the last [Element] read.
  Element _readDataset(Dataset ds) {
    Dataset parent = currentDS;
    currentDS = ds;
    log.debug2('$rbb readDataset: isExplicitVR(${_isEVR})');
    Element e;
    while (_hasRemaining(8)) {
      e = _readElement();
    }
    currentDS = parent;
    log.debug2('$ree end readDataset: isExplicitVR(${_isEVR})');
    return e;
  }

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => _hadPrefix != null;

/* Flush when working
  Element _readElement() {
    int eStart = _rIndex;
    Element e;
    int code = _readTagCode();
    log.debugDown('$rbb ${toDcm(code)} _readElement');
    if (code == 0) {
      _endOfLastValueRead = _rIndex - 4;
      log.warn('$_rrr zero encountered');
      if (_beyondPixelData) {
        _dsLengthInBytes = _rIndex - 4;
        throw new EndOfDataError('Zero encountered after '
            'PixelData @$_dsLengthInBytes');
      }
      _zeroEncountered(code);
    } else if (code == kPixelData) {
      _pixelDataStart = _rIndex;
      //e = (_isEVR) ? _readEVR(code) : _readIVR(code);
      _readEncapsulatedPixelData(code);
      _beyondPixelData = true;
      _pixelDataEnd = _rIndex;
      _endOfLastValueRead = _rIndex;
      log.debug('$rmm readPixelData: $_pixelDataStart - $_pixelDataEnd');
    } else {
      if (Tag.isGroupLengthCode(code)) _hadGroupLengths = true;
      e = (_isEVR) ? _readEVR(code) : _readIVR(code);
    }
    // Statistics
    _nElements++;
    if (Tag.isPrivateCode(code)) _nPrivateElements++;
    _endOfLastValueRead = _rIndex;
    elementList.add(eStart, _rIndex, e);
    _lastElementCode = e.code;
    log.debugUp('$ree ${_nElements}: ${e.info} _readElement');
    return e;
  }*/

  String get _evrString => (_isEVR) ? 'EVR' : 'IVR';

  Element _readElement() {
    int eStart = _rIndex;
    int code = _readTagCode();
    log.debugDown('$rbb readElement${toDcm(code)} $_evrString ');
    int vfLength =
        (_isEVR) ? _readEVRHdr(code, eStart) : _readIVRHdr(code, eStart);

    assert(_vr != null, 'Invalid null VR: vrCode(${toHex16(_vrCode)})');
    log.debug('$rmm $_vr start($eStart) vfLength($vfLength, ${toDcm
      (vfLength)})');

    if (code == 0) return _zeroEncountered(code);
    Element e;
    if (vfLength == kUndefinedLength) {
      e = _readULength(code, eStart, vfLength);
    } else {
      e = _readDefinedLength(code, eStart, vfLength);
    }
    log.debug1('$rmm   end of Element($_rIndex), $e');

    if (elementListEnabled) elementList.add(eStart, _rIndex, e);
    if (statisticsEnabled) {
      // Statistics
      _lastElement = e;
      _lastElementCode = code;
      _endOfLastValueRead = _rIndex;
    }
    if ((code >> 16).isOdd) _nPrivateElements++;
    log.debug2('$rmm   rootTotal: ${rootDS.total}');
    log.debug2('$rmm   rootMapLength: ${rootDS.map.length}');
    log.debug2('$rmm   rootDupMapLength: ${rootDS.dupMap.length}');
    log.debug2('$rmm   currentMapLength: ${currentMap.length}');
    log.debug2('$rmm   currentDupMapLength: ${currentDupMap.length}');
    log.debug2('$rmm   total: ${rootDS.total + rootDS.dupTotal}');
    //  int _dsElements = rootDS.total + rootDS.dupTotal + currentMap.length;
    //  if (_nElementsRead != _dsElements) log.debug('**** Unequal count');
    //  log.debugUp('$ree   ${_nElementsRead}: $e. DS(${_dsElements}) @end');
    log.debug1('$rmm   Read Total: ${_nElementsRead}');
    log.debugUp('$ree $_nElementsRead: $e @end');
    return e;
  }

  /// Adds an [Element] to a [Dataset].
  ///
  /// If the new [Element] is not valid and [allowInvalidValues] is [false],
  /// an [InvalidValuesError] is thrown; otherwise, the [Element] is added
  /// to both the [_issues] [Map] and to the [TagDataset]. The [_issues] [Map]
  /// can be used later to return an ValuesIssues for the [TagElement].
  ///
  /// If an [TagElement] with the same [Tag] is already contained in the
  /// [TagDataset] and [allowDuplicates] is [false], a [DuplicateElementError] is
  /// thrown; otherwise, the [TagElement] is added to both the [duplicates] [Map]
  /// and to the [TagDataset].
  void _add(Element eNew) {
    var v = currentMap[eNew.key];
    if (v == null) {
      // Urgent: add check for valid values with switch
      currentMap[eNew.key] = eNew;
    } else if (allowDuplicates && v != null) {
      log.warn('$rmm ** Duplicate Element: $eNew dups $v');
      if (v.vr != VR.kUN) {
        currentDupMap[eNew.key] = eNew;
      } else {
        currentMap[eNew.key] = eNew;
        currentDupMap[eNew.key] = v;
      }
    } else {
      if (throwOnError) throw new DuplicateElementError(v, eNew);
    }
  }

  // The current VR code and VR.
  int _vrCode;
  VR _vr;
  ElementMaker _maker;

  int _readEVRHdr(int code, int eStart) {
    _vrCode = _readUint16();
    _vr = VR.lookup(_vrCode);
    if (_vr == null) {
      log.warn('$rmm ** vr is Null: _vrCode(${toHex16(_vrCode)})');
      //+++     _showNext(_rIndex - 4);
    }
    if (doCheckVR) _checkVR(code, _vrCode);
    int vfLength;
    if (_vr.hasShortVF) {
      vfLength = _readUint16();
      _maker = ShortEVR.maker;
    } else {
      _skip(2);
      vfLength = _readUint32();
      _maker = LongEVR.maker;
    }
    assert(_checkRIndex());
    return vfLength;
  }

  //Urgent finish
  void _checkVR(int code, int vrCoder) {
    var tag = Tag.lookup(code);
    var goodVR = tag.vr;
    if (_vrCode == VR.kUN.code && tag.vr != VR.kUN) {
      log.warn('** UN VR vrCode($_vrCode) should be ${tag.vr})');
    } else if (_vrCode != VR.kUN.code && tag.vr.code == VR.kUN.code) {
      log.info('Unknown VR${toDcm(code)} $tag');
    } else if (_vrCode !=
        VR.kUN.code &&
        _vrCode != tag.vr.code) {
      var vr0 = VR.lookup(_vrCode);
      log.warn('** ${toDcm(code)} wrong VR $vr0($_vrCode) should be ${tag
          .vr})');
    } else {
      log.debug('$rmm ${toDcm(code)} VR.kUN');
    }
  }


  int _readIVRHdr(int code, int eStart) {
    assert(code > 0x0030000);
    if (doConvertUndefinedVR) {
      Tag tag = Tag.lookup(code);
      _vr = (tag == null) ? VR.kUN : tag.vr;
      _vrCode = _vr.code;
    } else {
      _vr = VR.kUN;
      _vrCode = VR.kUN.code;
    }
    int vfLength = _readUint32();
    _maker = IVR.maker;
    assert(_checkRIndex());
    return vfLength;
  }


  // Read an [Element] with a defined length.
  Element _readDefinedLength(int code, int eStart, int vfLength) {
    log.debug2('$rmm   readDLength: ${toDcm(code)} s:$eStart vfl: $vfLength');
    Element e;
    if (vfLength == 0) {
      log.debug2('$rmm     DLength Empty Element');
      e = _makeAndAddElement(eStart, _rIndex - eStart);
    } else if (_isSequence(code, _vrCode)) {
      log.debug2('$rmm     DLength Sequence');
      e = _readDSQ(code, eStart, vfLength);
    } else if (code == kPixelData) {
      _pixelDataStart = _rIndex;
      _pixelDataVR = VR.lookup(_vrCode);
      log.debug2('$rmm     DLength Pixel Data');
      e = _readSimpleDLength(code, eStart, vfLength);
      _beyondPixelData = true;
      _pixelDataEnd = _rIndex;
    } else {
      log.debug2('$rmm     Simple DLength ');
      e = _readSimpleDLength(code, eStart, vfLength);
    }
    log.debug2('$rmm     $e @end');
    assert(_checkRIndex());
    return e;
  }

  _readSimpleDLength(int code, int eStart, int vfLength) {
    log.down;
    log.debug1('$rbb  readSimpleDLength');
    Element e;
    if (code > 0x3000 && Tag.isGroupLengthCode(code)) _hadGroupLengths = true;
    log.debug1('$rmm   ${toDcm(code)}, start($eStart) vfLength'
        '($vfLength), $_evrString');
    _rIndex = _rIndex + vfLength;
    var eLength = _rIndex - eStart;
    e = _makeAndAddElement(eStart, eLength);
    log.debug1('$ree   $e @end');
    log.up;
    return e;
  }

  Element _makeAndAddElement(eStart, eLength) {
    _nElementsRead++;
    var ebd = bd.buffer.asByteData(eStart, eLength);
    var e = _maker(ebd);
    _add(e);
    return e;
  }

  /// Read an [Element] with [kUndefinedLength] Value Length Field.
  Element _readULength(int code, int eStart, int vfLength) {
    log.down;
    log.debug2('$rbb readULength code${toDcm(code)} eStart($eStart)');
    assert(vfLength == kUndefinedLength);
    Element e;
    if (_isSequence(code, _vrCode)) {
      log.debug2('$rmm   ULength Sequence(${toDcm(code)}');
      e = _readUSQ(code, eStart, vfLength);
    } else if (code == kPixelData) {
      log.debug2('$rmm   ULength Pixel Data(${toDcm(code)}');
      e = _readFragmentedPixelData(eStart);
    } else {
      log.debug2('$rmm   Simple ULength element(${toDcm(code)}');
      e = _readSimpleULength(code, eStart);
    }
    assert(_checkRIndex());
    log.debug2('$ree $e   @end');
    log.up;
    return e;
  }

  /// Read a simple Undefined Length [Element], i.e. not a [Sequence],
  /// and not an encapsulated [kPixelData].
  Element _readSimpleULength(int code, int eStart) {
    log.down;
    log.debug1('$rbb readSimpleULength code(${toDcm(code)}eStart($eStart)');
    int endOfVF = _findEndOfULengthVF();
    int eLength = endOfVF - eStart;
    _rIndex = endOfVF + 8;
    ByteElement e;
    if (code == kPixelData) {
      e = _makePixelData(eStart, eLength);
    } else {
      e = _makeAndAddElement(eStart, eLength);
    }
    log.debug1('$ree   $e @end');
    log.up;
    return e;
  }

  BytePixelData _makePixelData(eStart, eLength, [VFFragments fragments]) {
    log.debugDown('$rbb _makePixelData: '
        '$eStart - $eLength = ${eStart + eLength}, $fragments');
    var ebd = bd.buffer.asByteData(eStart, eLength);
    var e = (_isEVR)
        ? new EVRBytePixelData(ebd, fragments)
        : new IVRBytePixelData(ebd, fragments);
    _add(e);
    assert(_checkRIndex());
    log.debugUp('$ree   fragments: $fragments @end');
    return e;
  }

  /// Reads an encapsulated (compressed) [kPixelData] [Element].
  Element _readFragmentedPixelData(int eStart) {
    log.debugDown('$rbb readFragmentedPixelData, i.e. ULength');
    assert(_vrCode == VR.kOB.code ||
        _vrCode == VR.kOW.code ||
        _vrCode == VR.kUN.code);
    _pixelDataStart = _rIndex;
    _pixelDataVR = VR.lookup(_vrCode);
    if (_vrCode != VR.kOB.code && _vrCode != VR.kUN.code) {
      VR vr = VR.lookup(_vrCode);
      log.warn('$rmm ** Invalid VR($vr) for Encapsulated TS: $_ts');
      _hadParsingErrors = true;
    }
    var fragments = _readFragments();
    var eLength = _rIndex - eStart;
    _pixelDataEnd = _rIndex;
    _beyondPixelData = true;
    _nElementsRead++;
    var e = _makePixelData(eStart, eLength, fragments);
    log.debugUp('$ree   fragments: $fragments @end');
    return e;
  }

  /// If this is a Sequence, it is wither empty, in which case the next
  /// 32-bits will be a [kSequenceDelimitationItem32Bit]; or it is not
  /// empty, in which case the next 32 bits will be an [kItem32Bit] value.
  //Note: This is separated from [_isIVRSQ] so that it integrates.
  bool _isSequence(int code, int vrCode) =>
      (_isEVR && _isEVRSQ(code, vrCode)) || (!_isEVR && _isIVRSQ(code, vrCode));

  bool _isEVRSQ(int code, int vrCode) {
    assert(_isEVR);
    if (vrCode == VR.kSQ.code) return true;
    if (vrCode != VR.kUN.code) return false;
    return _checkIfSequence(code, vrCode);
  }

  bool _isIVRSQ(int code, int vrCode) {
    assert(!_isEVR);
    return _checkIfSequence(code, vrCode);
  }

  bool _checkIfSequence(int code, int vrCode) {
    log.debug2('$rmm       checkIfSequence: vrCode($vrCode)');
    assert((_isEVR && vrCode == VR.kUN.code) || !_isEVR);
    if (code == kPixelData) return false;
    int delimiter = _getUint32(_rIndex);
    log.debug2('$rmm       @end');
    return (delimiter == kItem32BitLE ||
            delimiter == kSequenceDelimitationItem32BitLE)
        ? true
        : false;
  }

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem32Bit] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads a [kUndefinedLength] Sequence.
  Element _readUSQ(int code, int eStart, int vfLength) {
    assert(vfLength == kUndefinedLength);
    log.debugDown('$rbb readUSQ: ${_startSQ(code, eStart, vfLength)}');
    // FIX: give this a type when understood.
    var items = [];
    while (!_isSequenceDelimiter()) {
      items.add(_readItem());
      _checkRIndex();
    }
    var sq = _makeSQ(code, eStart, items);
    _nDSequences++;
    log.debugUp('$ree   $sq ${items.length} items @end');
    return sq;
  }

  /// Reads a defined [vfLength].
  Element _readDSQ(int code, int eStart, int vfLength) {
    assert(vfLength != kUndefinedLength);
    log.debugDown('$rbb readDSQ: ${_startSQ(code, eStart, vfLength)}');
    // FIX: give this a type when understood.
    var items = [];
    int eEnd = _rIndex + vfLength;
    while (_rIndex < eEnd) {
      items.add(_readItem());
      _checkRIndex();
    }
    var sq = _makeSQ(code, eStart, items);
    _nUSequences++;
    log.debugUp('$ree  $sq ${items.length} items readDS@ @end');
    return sq;
  }

  Element _makeSQ(int code, int eStart, List items) {
    log.down;
    log.debug2('$rmm _makeSQ: $eStart - $items');
    // Keep, but only use for debugging.
    //_showNext(_rIndex);
    int eLength = _rIndex - eStart;
    log.debug2('$rmm   eLength($eLength), readDLengthSQ');
    _nElementsRead++;
    var ebd = bd.buffer.asByteData(eStart, eLength);
    Element sq = (_isEVR)
        ? new EVRByteSQ(ebd, currentDS, items)
        : new IVRByteSQ(ebd, currentDS, items);
    _add(sq);
    if (Tag.isPrivateCode(code)) _nPrivateSequences++;
    _nSequences++;
    log.debug2('$rmm   makeSQ @end');
    log.up;
    return sq;
  }

  String _startSQ(int code, int eStart, int vfLength) =>
      '${toDcm(code)} eStart($eStart) '
      'vfLength ($vfLength, ${toHex32(vfLength)})';

  /// Returns [true] if the sequence delimiter is found at [_rIndex].
  bool _isSequenceDelimiter() =>
      _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  //TODO: put _checkIndex in appropriate places
  bool _checkRIndex() {
    if (_rIndex.isOdd) {
      var msg = 'Odd Lenth Value Field at @$_rIndex - incrementing';
      log.warn('$rmm ** $msg');
      _skip(1);
      _nOddLengthValueFields++;
      if (throwOnError) throw msg;
    }
    return true;
  }

  /// Returns [true] if the [kItemDelimitationItem32Bit] delimiter is found.
  bool _checkForItemDelimiter() =>
      _checkForDelimiter(kItemDelimitationItem32BitLE);

  final kItem = toHex32(kItem32BitLE);

  /// Returns an [Item] or Fragment.
  Dataset _readItem() {
    assert(hasRemaining(8));
    int itemStart = _rIndex;
    int itemEnd;
    // int code = _readTagCode();
    int delimiter = _readUint32();
    assert(delimiter == kItem32BitLE, 'Invalid Item code: ${toDcm(delimiter)}');
    int vfLength = _readUint32();

    String actual = toHex32(delimiter);
    log.debugDown('$rbb readItem kItem($kItem), actual($actual) '
        '${toVFLength(vfLength)}, itemEnd($itemEnd)}');
    log.debug1('$rmm   ${toHadULength(vfLength)}');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    Dataset parentDS = currentDS;
    var parentMap = currentMap;
    var parentDupMap = currentDupMap;
    var map = <int, Element>{};
    var dupMap = <int, Element>{};
    currentMap = map;
    currentDupMap = dupMap;

    Dataset item;
    try {
      if (vfLength == kUndefinedLength) {
        log.debug2('$rmm   Undefined Item length');
        while (!_checkForItemDelimiter()) {
          //   _add(_readElement());
          _readElement();
        }
        itemEnd = _rIndex;
      } else {
        itemEnd = _rIndex + vfLength;
        log.debug2('$rmm   Fixed Item length: itemEnd($itemEnd)');
        while (_rIndex < itemEnd) {
          // _add(_readElement());
          _readElement();
        }
      }
    } on EndOfDataError {
      log.debugUp('$ree   @end');
      log.reset;
      rethrow;
    } catch (e) {
      _hadParsingErrors = true;
      log.error(e);
      log.reset;
      rethrow;
    } finally {
      log.debug('$rmm   item.length(${currentDS.length}');
      // Restore previous parent
      currentDS = parentDS;
      currentMap = parentMap;
      currentDupMap = parentDupMap;
      // Keep, but only use for debugging.
      //  _showNext(_rIndex);
      var ibd = bd.buffer.asByteData(itemStart, itemEnd - itemStart);
      item = makeItem(ibd, currentDS, vfLength, map, dupMap);
      log.debugUp('$ree   ${item.length} Elements @end');
    }
    return item;
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced past the Value Length Field;
  /// otherwise, readIndex does not change
  bool _checkForDelimiter(int target) {
    int delimiter = _getUint32(_rIndex);
    if (delimiter == target) {
      _skip(4);
      int delimiterLength = _readUint32();
      if (delimiterLength != 0) {
        _delimiterLengthWarning(delimiterLength);
      }
      return true;
    }

    return false;
  }

  void _delimiterLengthWarning(int dLength) {
    _nonZeroDelimiterLengths++;
    log.warn('$rmm ** Encountered non-zero delimiter length($dLength)');
  }

  /// Reads the [kUndefinedLength] Value Field until the
  /// [kSequenceDelimiter] is found. _Note_: Since the Value
  /// Field is 16-bit aligned, it must be checked 16 bits at a time.
  int _findEndOfULengthVF() {
    log.down;
    log.debug1('$rbb findEndOfULengthVF');
    while (_isReadable) {
      if (_readUint16() != kDelimiterFirst16Bits) continue;
      if (_readUint16() != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    if (!_isReadable) throw new EndOfDataError("_findEndOfVF");
    int delimiterLength = _readUint32();
    if (delimiterLength != 0) _delimiterLengthWarning(delimiterLength);
    int endOfVF = _rIndex - 8;
    _endOfLastValueRead = _rIndex;
    log.debug1('$ree   endOfVR($endOfVF) eEnd($_rIndex) @end');
    log.up;
    return endOfVF;
  }

  VFFragments _readFragments() {
    log.debugDown('$rbb readFragements');
    // rIndex at first kItem delimiter
    var fragments = <Uint8List>[];
    // int code = _readTagCode();
    int code = _readUint32();
    int fragNumber = 0;
    do {
      assert(code == kItem32BitLE, 'Invalid Item code: ${toDcm(code)}');
      int vfLength = _readUint32();
      assert(
          vfLength != kUndefinedLength, 'Invalid length: ${toDcm(vfLength)}');
      int startOfVF = _rIndex;
      _rIndex += vfLength;
      fragments.add(bd.buffer.asUint8List(startOfVF, _rIndex - startOfVF));
      fragNumber++;
      log.debug1('$rmm   fragment: $fragNumber, vfLength: $vfLength');
      code = _readUint32();
    } while (code != kSequenceDelimitationItem32BitLE);
    // Read the Sequence Delimitation Item length field.
    int vfLength = _readUint32();
    if (vfLength != 0)
      log.warn('$rmm ** Pixel Data Sequence delimiter has non-zero '
          'value: $code/0x${toHex32(code)}');
    var vfFragments = new VFFragments(fragments);
    var delimiter = _getUint32(_rIndex - 8);
    assert(delimiter == kSequenceDelimitationItem32BitLE);
    log.debugUp('$ree   $vfFragments @end');
    return vfFragments;
  }

  /// Reads a group and element and combines them into a Tag.code.
  int _readTagCode() {
    assert(_rIndex.isEven);
    int code = _peekTagCode();
    _rIndex += 4;
    return code;
  }

  /// Peek at next tag - doesn't move the [_rIndex].
  int _peekTagCode() {
    assert(_rIndex.isEven);
    int group = _getUint16(_rIndex);
    int elt = _getUint16(_rIndex + 2);
    return (group << 16) + elt;
  }

  int _readUint16() {
    assert(_rIndex.isEven);
    int v = _getUint16(_rIndex);
    _rIndex += 2;
    return v;
  }

  int _readUint32() {
    assert(_rIndex.isEven);
    int v = _getUint32(_rIndex);
    _rIndex += 4;
    return v;
  }

  int _getUint32(int offset) {
    assert(offset.isEven);
    return bd.getUint32(offset, Endianness.LITTLE_ENDIAN);
  }

  int _getUint16(int offset) {
    assert(offset.isEven);
    return bd.getUint16(offset, Endianness.LITTLE_ENDIAN);
  }

  int _skip(int n) {
    assert(_rIndex.isEven);
    int index = _rIndex + n;
    _rIndex = RangeError.checkValidRange(0, index, _bdLength);
    return _rIndex;
  }

//  String _readUtf8String(int length) => UTF8.decode(_readChars(length));

  void _warnIfShortFile() {
    if (_wasShortFile) {
      var s = 'Short file error: length(${_bdLength}) $path';
      log.warn('$rmm ** $s');
      if (throwOnError) throw new ShortFileError('Length($_bdLength) $path');
    }
  }

  // **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _rrr => 'R@$_rIndex';

  /// The beginning of reading an [Element] or [Item].
  String get rbb => '> $_rrr';

  /// In the middle of reading an [Element] or [Item]
  String get rmm => '| $_rrr  ';

  /// The end of reading an [Element] or [Item]
  String get ree => '< $_rrr  ';

  bool _checkAllZeros(int start, int end) {
    for (int i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  /// Returns [true] if there are only trailing zeros at the end of the
  /// Object being parsed.
  Element _zeroEncountered(int code) {
    _endOfLastValueRead = _rIndex - 4;
    log.warn('$rmm ** Zero encountered: beyondPixelData: $_beyondPixelData');
    if (_beyondPixelData) {
      _dsLengthInBytes = _rIndex - 4;
      throw new EndOfDataError('Zero encountered after '
          'PixelData @$_dsLengthInBytes');
    }
    _hadTrailingBytes = true;
    int mark = _rIndex - 4;
    log.warn('$rmm Zero code($code) encountered @$mark');
    if (_checkAllZeros(_rIndex, _bdLength)) {
      _hadTrailingZeros = true;
      log.warn('$rmm Returning from reading zeros from @$mark to @$_rIndex '
          'in "$path"');
      return null;
    }
    //TODO: make this work better
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
        return null;
      }
    }
    return null;
  }

  _showNext(int start) {
    if (_isEVR) {
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

  int _getCode(int start) {
    if (_hasRemaining(4)) {
      int group = _getUint16(start);
      int elt = _getUint16(start);
      return group << 16 & elt;
    }
    return null;
  }

  void _showShortEVR(int start) {
    if (_hasRemaining(8)) {
      int code = _getCode(start);
      int vrCode = _getUint16(start + 4);
      VR vr = VR.lookup(vrCode);
      int vfLength = _getUint16(start + 6);
      log.debug('$rmm Short EVR: ${toDcm(code)} $vr vfLength: $vfLength');
    }
  }

  void _showLongEVR(int start) {
    if (_hasRemaining(8)) {
      int code = _getCode(start);
      int vrCode = _getUint16(start + 4);
      VR vr = VR.lookup(vrCode);
      int vfLength = _getUint32(start + 8);
      log.debug('$rmm Long EVR: ${toDcm(code)} $vr vfLength: $vfLength');
    }
  }

  void _showIVR(int start) {
    if (_hasRemaining(8)) {
      int code = _getCode(start);
      Tag tag = Tag.lookup(code);
      if (tag != null) log.debug(tag);
      int vfLength = _getUint16(start + 4);
      log.debug('$rmm IVR: ${toDcm(code)} vfLength: $vfLength');
    }
  }

  void _rootDSStats() {
    int dsTotal = rootDS.total;
    int dsTop = rootDS.length;
    var dsSQs = _getSequences(rootDS.map);
    int dsDupTotal = rootDS.dupTotal;
    int dsDupTop = rootDS.duplicates.length;
    var dupSQs = _getSequences(rootDS.dupMap);
    log.debug('$rmm nElementsRead: $_nElementsRead');
    log.debug('$rmm nSequences $_nSequences');
    log.debug('$rmm rootDS Stats: Total($dsTotal), '
        'Top Level($dsTop), SQs(${dsSQs.length})');
    log.debug('$rmm        Dups: Total($dsDupTotal), '
        'Top Level($dsDupTop), SQs(${dupSQs.length})');
  }

  List<Element> _getSequences(Map map) {
    List<Element> sqs = [];
    for (Element e in map.values) {
      if (e.isSequence) {
        sqs.add(e);
      }
    }
    return sqs;
  }

  String toVFLength(int vfl) => 'vfLength($vfl, ${toHex32(vfl)})';
  String toHadULength(int vfl) =>
      'HadULength(${(vfl == kUndefinedLength) ? "true": "false"})';
}
