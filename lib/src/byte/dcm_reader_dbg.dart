// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/dataset.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'dcm_reader_interface.dart';

//TODO: redoc to reflect current state of code

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
abstract class DcmReader extends DcmReaderInterface {
  /// The [ByteData] being read.
  @override
  final ByteData rootBD;

  // Input parameters
  final bool async;
  final bool fast;
  final bool fmiOnly;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// If [true] and Preamble and Prefix are not present, abort reading.
  final bool allowMissingPrefix;

  /// If [true] and [FMI] is not present, abort reading.
  final bool allowMissingFMI;

  /// If [true], then duplicate [Element]s will be stored.
  final bool allowDuplicates;

  /// Only read the file if it has the same [TransferSyntax] as [targetTS].
  final TransferSyntax targetTS;

  //Urgent: todo make this a parameter
  /// If [true] any EVR [Element]s will be checked for being Sequences.
  final bool checkForUNSequence;

  /// If [true] elements with VR.kUN will be converted to correct VR if known.
  final bool doConvertUndefinedVR;

  /// If [true] the [ByteData] buffer ([rootBD] will be reused.
  final bool reUseBD;

  final DecodingParameters decoding;

  // **** stats and debugging
  final bool statisticsEnabled = true;
  final bool elementListEnabled = true;
  final ElementList elementList = new ElementList();

  ByteData bdRead;
  final List<String> exceptions = <String>[];

  // ParseInfo values
  bool _isEVR;
  int _nElementsRead = 0;
  int _nSequencesRead = 0;
  int _nItemsRead = 0;
  int _nDSequencesRead = 0;
  int _nUSequencesRead = 0;
  int _nPrivateElementsRead = 0;
  int _nPrivateSequencesRead = 0;

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

  TransferSyntax _tsUid;
  VR _pixelDataVR;
  int _pixelDataStart;
  int _pixelDataEnd;
  int _lastElementCode;
  Element _lastTopLevelElementRead;
  Element _lastElementRead;
  int _endOfLastValueRead;
  bool _beyondPixelData = false;
  bool _endOfDataError = false;

  /// The index where the last element in the root [Dataset] ended.
  int _dsLengthInBytes;

  bool _wasShortFile = false;
  bool _hadTrailingBytes = false;
  bool _hadTrailingZeros = false;
  int _bytesUnread = 0;

  /// The current read index.
  int _rIndex = 0;

  // *** Constructors ***

  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReader(this.rootBD,
      {this.path = "",
      this.async = true,
      this.fast: true,
      this.fmiOnly = false,
      this.throwOnError = true,
      this.allowMissingPrefix = false,
      this.allowMissingFMI = false,
      this.allowDuplicates = true,
      this.targetTS,
      this.doConvertUndefinedVR = true,
      //TODO: read into preallocated buffer that is used over and over.
      this.reUseBD = true,
      this.checkForUNSequence = false,
      this.decoding = DecodingParameters.kNoChange})
      : _wasShortFile = rootBD.lengthInBytes < shortFileThreshold {
    //  log.debug('ByteData length: ${bd.lengthInBytes}');
    if (_wasShortFile) {
      var s = 'Short file error: length(${rootBD.lengthInBytes}) $path';
      _warn('$s $_rrr');
      if (throwOnError) throw new ShortFileError('Length($rootBD.lengthInBytes) $path');
    }
  }

  bool get isEVR => _isEVR;

  @override
  Dataset get rootDS;

  bool get _isReadable => _rIndex < rootBD.lengthInBytes;

  /// External interface for testing.
  bool get isReadable => _isReadable;

  bool _hasRemaining(int n) => (_rIndex + n) <= rootBD.lengthInBytes;

  bool hasRemaining(int n) => _hasRemaining(n);

  Uint8List get buffer => rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  Uint8List get bytes =>
      bdRead.buffer.asUint8List(bdRead.offsetInBytes, bdRead.lengthInBytes);

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  ParseInfo getParseInfo() {
    return new ParseInfo(
        _isEVR,
        _nElementsRead,
        _nSequencesRead,
        _nPrivateElementsRead,
        _nPrivateSequencesRead,
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
        _tsUid,
        _pixelDataVR,
        _pixelDataStart,
        _pixelDataEnd,
        _lastTopLevelElementRead,
        _lastElementCode,
        _endOfLastValueRead,
        _dsLengthInBytes,
        rootBD.lengthInBytes,
        shortFileThreshold,
        _wasShortFile,
        _hadTrailingBytes,
        _hadTrailingZeros,
        exceptions);
  }

  bool dcmReadFMI({bool checkPreamble = true, bool allowMissingPrefix = false}) {
    currentDS = rootDS;
    currentMap = rootDS.map;
    duplicates = rootDS.dupMap;
    return _readFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
  }

  /// Reads a Root [Dataset] from [this] and returns it.
  /// If an error is encountered and [throwOnError] is [true],
  /// an Error will be thrown; otherwise, returns [null].
  Dataset dcmReadRootDataset(
      {bool allowMissingFMI = false,
      bool checkPreamble = true,
      bool allowMissingPrefix = false}) {
    log.debug('$rbb readRootDataset');
    currentDS = rootDS;
    currentMap = rootDS.map;
    duplicates = rootDS.dupMap;
    _hadFmi =
        _readFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
    if (!_hadFmi && !allowMissingFMI) return null;
    if (targetTS != null && _tsUid != targetTS) return rootDS;

    if (!system.isSupportedTransferSyntax(_tsUid.asString)) {
      _hadParsingErrors = true;
      _error('$ree Unsupported TS: $_tsUid @end');
      if (throwOnError) throw new InvalidTransferSyntaxError(_tsUid);
      return rootDS;
    }

    log.debug('$rmm _isEVR: $_isEVR');
    try {
      currentDS = rootDS;
      log.debug1('$rbb readDataset: isExplicitVR(${_isEVR})');
      while (_hasRemaining(8)) readElement();
      log.debug1('$ree end readDataset: isExplicitVR(${_isEVR})');
      assert(identical(currentDS, rootDS));
    } on EndOfDataError {
      log.info0('$_rrr EndOfDataError');
      _endOfDataError = true;
    } on ShortFileError {
      rethrow;
    } on RangeError catch (ex) {
      _error('$ex\n $stats');
      if (_beyondPixelData) log.info0('$_rrr Beyond Pixel Data');
      // Keep: *** Keep, but only use for debugging.
      if (throwOnError) rethrow;
    } catch (ex) {
      _error('$_rrr $ex\n $stats');
      // *** Keep, but only use for debugging.
      if (throwOnError) rethrow;
    } finally {
      bdRead = rootBD.buffer.asByteData(0, _endOfLastValueRead);
//      assert(_rIndex == _endOfLastValueRead,
//          '_rIndex($_rIndex), _endOfLastValueRead($_endOfLastValueRead)');
      _bytesUnread = rootBD.lengthInBytes - _rIndex;
      _hadTrailingBytes = _bytesUnread > 0;
      _hadTrailingZeros = _checkAllZeros(_endOfLastValueRead, rootBD.lengthInBytes);
      _dsLengthInBytes = _endOfLastValueRead;
      assert(_dsLengthInBytes == bdRead.lengthInBytes);
    }

    log.debug1(stats);
    if (_rIndex != bdRead.lengthInBytes) {
      _warn('End of Data with _rIndex($_rIndex) != bdRead.length'
          '(${bdRead.lengthInBytes}) $_rrr');
      _dsLengthInBytes = _rIndex;
      _endOfLastValueRead = _rIndex;
      _hadTrailingBytes = (bdRead.lengthInBytes != rootBD.lengthInBytes);
      if (_hadTrailingBytes)
        _hadTrailingZeros = _checkAllZeros(_rIndex, rootBD.lengthInBytes);
    }

    int rootDSTotal = rootDS.total + rootDS.dupTotal;
    if (_nElementsRead != rootDSTotal) {
      var msg = 'Inconsistent Elements Error: '
          '_nElementsRead($_nElementsRead), rootDS.total(${rootDS.total}) '
          'rootDS.dupTotal(${rootDS.dupTotal})  '
          '= ${rootDS.total + rootDS.dupTotal}';
      _error(msg);
      if (throwOnError) throw msg;
    }
    return rootDS;
  }

  /// External Interface for testing.
  Element readElement() => _readElement();

  @override
  String toString() => '$runtimeType: rootDS: $rootDS, currentDS: $currentDS';

  // **** Internal Methods

  /// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
  /// Returns [true] if a valid Preamble and Prefix where read.
  bool _readPrefix(bool checkPreamble) {
    String readAsciiPrefix() {
      var chars = rootBD.buffer.asUint8List(_rIndex, 4);
      _rIndex += 4;
      return ASCII.decode(chars);
    }

    try {
      String msg = "";
      if (_rIndex != 0) msg += 'Attempt to read DICOM Prefix at ByteData[$_rIndex]\n';
      if (_hadPrefix != null) msg += 'Attempt to re-read DICOM Preamble and Prefix.\n';
      if (rootBD.lengthInBytes <= 132) msg += 'ByteData length(${rootBD.lengthInBytes}) < 132';
      if (msg.length > 0) {
        _error(msg);
        return false;
      }
      if (checkPreamble) {
        _preambleWasZeros = true;
        _preamble = rootBD.buffer.asUint8List(0, 128);
        for (int i = 0; i < 128; i++) if (rootBD.getUint8(i) != 0) _preambleWasZeros = false;
      }
      _skip(128);

      final String prefix = readAsciiPrefix();
      bool v = (prefix == "DICM") ? true : false;
      if (v == false) {
        _warn('No DICOM Prefix present @$_rrr');
        _skip(-132);
      }
      return v;
    } catch (e) {
      _error('Error reading prefix @$_rrr: $e\n  of path: $path');
      return false;
    }
  }

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  bool _readFMI({bool checkPreamble = true, bool allowMissingPrefix = false}) {
    _isEVR = true;
    assert(currentDS == rootDS);
    log.debug('$rbb readFmi($currentDS)', -1);
    assert(_hadPrefix == null);
    _hadPrefix = _readPrefix(checkPreamble);
    if (!_hadPrefix && !allowMissingPrefix) {
      log.debug('$ree  No Prefix', 1);
      return false;
    }
    log.debug1('$rmm readFMI: prefix($_hadPrefix) $rootDS');
    int eStart = _rIndex;
    int code;
    try {
      while (_isReadable) {
        code = _peekTagCode();
        log.debug2('$rmm code(${dcm(code)}');
        if (code >= 0x00030000) {
          log.debug('$rmm   End of FMI');
          break;
        } else {
          Element e = _readElement();
          log.debug2('$rmm ${elementInfo(e)}');
        }
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hadParsingErrors = true;
      _warn('Failed to read FMI: "$path"\nException: $x\n $_rrr');
      _warn('  File length: ${rootBD.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = 0;
      log.debug('$ree readFMI Invalid TS catch: $x', -1);
      rethrow;
    } catch (x) {
      if (code == 0) _zeroEncountered(code);
      _hadParsingErrors = true;
      _error('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${rootBD.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = eStart;
      log.debug('$ree readFMI Catch: $x', -1);
      rethrow;
    }
    if (!isReadable) {
      throw new EndOfDataError('_readFMI');
    }
    _hadFmi = true;
    log.debug2('$rmm hadFMI: $_hadFmi');

    // Get TS or if not present use default
    _tsUid = rootDS.transferSyntax;
    if (_tsUid == null) _tsUid = system.defaultTransferSyntax;
    _isEVR = !_tsUid.isImplicitLittleEndian;

    log.debug1('$rmm isExplicitVR: $_isEVR');
    log.debug('$rmm TS:${_tsUid}');
    log.debug1('$rmm targetTS: $targetTS');
    log.debug('$ree readFmi: ${rootDS.info}', 1);
    return true;
  }

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => _hadPrefix != null;

  /// Returns a [String] indicating whether VR is Explicit or Implicit.
  String get _evrString => (_isEVR) ? 'EVR' : 'IVR';

  /// All [Elements are read by this method.
  Element _readElement() {
    int eStart = _rIndex;
    int code = _readTagCode();
    log.debug('$rbb readElement${dcm(code)} $_evrString ', 1);
    if (code == 0) {
      _skip(-4); // undo readTagCode
      _zeroEncountered(code);
      log.debug('$ree Zero encountered', -1);
      return null;
    }
    int vfLength = (_isEVR) ? _readEVRHdr(code, eStart) : _readIVRHdr(code, eStart);

    assert(_vr != null, 'Invalid null VR: vrCode(${hex16(_vrCode)})');
    log.debug('$rmm $_vr start($eStart) vfLength($vfLength, ${dcm(vfLength)})');

    Element e;
    if (code == kPixelData) {
      e = _readPixelData(eStart, vfLength);
    } else if (vfLength == kUndefinedLength) {
      e = _readULength(code, eStart, vfLength);
    } else {
      e = _readDLength(code, eStart, vfLength);
    }

    //Enhancement: only gather statistics when statisticsEnables is true
    // Statistics
    if (statisticsEnabled) {
      _nElementsRead++;
      _endOfLastValueRead = _rIndex;
      if (elementListEnabled) elementList.add(eStart, _rIndex, e);
      _lastTopLevelElementRead = e;
      _lastElementCode = code;
      if ((code >> 16).isOdd) _nPrivateElementsRead++;
    }
    // For debugging only
    _tagCode = code;
    log.debug('$ree $_nElementsRead: ${elementInfo(e)} @end', -1);
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
      _warn('Duplicate Element: current($v) duplicat(${elementInfo(eNew)}) $_rrr');
      if (v.vr != VR.kUN) {
        duplicates[eNew.key] = eNew;
      } else {
        currentMap[eNew.key] = eNew;
        duplicates[eNew.key] = v;
      }
    } else {
      if (throwOnError) throw new DuplicateElementError(v, eNew);
    }
  }

  // The current tag code, tag, VR code, VR, and VR Index.
  int _tagCode;
  int _vrCode;
  Tag _tag;
  VR _vr;
  int _vrIndex;
  int _vfLength;

  int _readEVRHdr(int code, int eStart) {
    _vrCode = _readUint16();
    _vr = VR.lookup(_vrCode);
    _vrIndex = _vr.index;
    log.debug2('$rmm readEVRHdr vrCode(${hex16(_vrCode)}) $_vr');
    if (_vr == null) {
      _warn('VR is Null: _vrCode(${hex16(_vrCode)}) $_rrr');
      _showNext(_rIndex - 4);
    }
    if (decoding.doCheckVR) _checkVR(code, _vrCode);
    if (_vr.hasShortVF) {
      log.debug2('$rmm readEVRHdr Short VR');
      _vfLength = _readUint16();
    } else {
      log.debug2('$rmm readEVRHdr Long VR');
      _skip(2);
      _vfLength = _readUint32();
    }
    assert(_checkRIndex());
    return _vfLength;
  }

  //TODO: add VR.kSSUS, etc. to dictionary
  /// checks that code & vrCode are
  void _checkVR(int code, int vrCode, [bool warnOnUN = false]) {
    _tag = Tag.lookupByCode(code);
    if (_tag == null) {
      _warn('Unknown Tag Code(${dcm(code)}) $_rrr');
    } else if (vrCode == VR.kUN.code && _tag.vr != VR.kUN) {
      //Enhancement remove PTags with VR.kUN and add multi-values VRs
      _warn('${dcm(code)} VR.kUN($vrCode) should be ${_tag.vr} $_rrr');
    } else if (vrCode != VR.kUN.code && _tag.vr.code == VR.kUN.code) {
      if (code != kPixelData && warnOnUN == true) {
        if (_tag is PDTag && _tag is! PDTagKnown) {
          log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Data');
        } else if (_tag is PCTag && _tag is! PCTagKnown) {
          log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Creator $_tag');
        } else {
          log.info0('$pad ${dcm(code)} VR.kUN: $_tag');
        }
      }
    } else if (vrCode != VR.kUN.code && vrCode != _tag.vr.code) {
      var vr0 = VR.lookup(vrCode);
      _warn('${dcm(code)} Wrong VR $vr0($vrCode) '
          'should be ${_tag.vr} $_rrr');
    }
  }

  int _readIVRHdr(int code, int eStart) {
    if (doConvertUndefinedVR) {
      Tag tag = Tag.lookupByCode(code);
      _vr = (tag == null) ? VR.kUN : tag.vr;
      _vrCode = _vr.code;
      _vrIndex = _vr.index;
    } else {
      _vr = VR.kUN;
      _vrCode = VR.kUN.code;
      _vrIndex = VR.kUN.index;
    }
    _vfLength = _readUint32();
    //   _maker = IVR.maker;
    assert(_checkRIndex());
    return _vfLength;
  }

  // Read an [Element] with a defined length.
  Element _readDLength(int code, int eStart, int vfLength) {
    log.debug2('$rmm   readDLength: ${dcm(code)} s:$eStart vfl: $vfLength');
    Element e;
    if (_isSequence(code, _vrCode)) {
      log.debug2('$rmm     DLength Sequence');
      e = _readDSQ(code, eStart, vfLength);
    } else if (vfLength == 0) {
      log.debug2('$rmm     DLength Empty Element');
      e = _makeAndAddElement(eStart, _rIndex - eStart);
    } else {
      log.debug2('$rmm     Simple DLength ');
      e = _readSimpleDLength(code, eStart, vfLength);
    }
    log.debug2('$rmm     ${elementInfo(e)} @end');
    assert(_checkRIndex());
    return e;
  }

  Element _readSimpleDLength(int code, int eStart, int vfLength) {
    log.down;
    log.debug1('$rbb  readSimpleDLength');
    Element e;
    if (code > 0x3000 && Tag.isGroupLengthCode(code)) _hadGroupLengths = true;
    log.debug1('$rmm   ${dcm(code)}, start($eStart) vfLength'
        '($vfLength), $_evrString');
    _rIndex = _rIndex + vfLength;
    var eLength = _rIndex - eStart;
/*    if (code == kPixelData) {
      e = _makePixelData(eStart, eLength);
    } else {*/
    e = _makeAndAddElement(eStart, eLength);
    //   }
    log.debug1('$ree   ${elementInfo(e)} @end');
    log.up;
    return e;
  }

  Element _makeAndAddElement(eStart, eLength) {
    var ebd = rootBD.buffer.asByteData(eStart, eLength);
    var e = makeElement(_tag.vrIndex, _tag, ebd, _vfLength);
    _add(e);
    return e;
  }

  /// Read an [Element] with [kUndefinedLength] Value Length Field.
  Element _readULength(int code, int eStart, int vfLength) {
    log.down;
    log.debug2('$rbb readULength code${dcm(code)} eStart($eStart)');
    assert(vfLength == kUndefinedLength);
    Element e;
    if (_isSequence(code, _vrCode)) {
      log.debug2('$rmm   ULength Sequence(${dcm(code)}');
      e = _readUSQ(code, eStart, vfLength);
/*    } else if (code == kPixelData) {
      log.debug2('$rmm   ULength Pixel Data(${dcm(code)}');
      e = _readFragmentedPixelData(eStart, vfLength);*/
    } else {
      log.debug2('$rmm   Simple ULength element(${dcm(code)}');
      e = _readSimpleULength(code, eStart, vfLength);
    }
    assert(_checkRIndex());
    log.debug2('$ree ${elementInfo(e)}   @end');
    log.up;
    return e;
  }

  /// Read a simple Undefined Length [Element], i.e. not a [Sequence],
  /// and not an encapsulated [kPixelData].
  Element _readSimpleULength(int code, int eStart, int vfLength) {
    assert(vfLength == kUndefinedLength);
    log.down;
    log.debug1('$rbb readSimpleULength code(${dcm(code)}eStart($eStart)');
    int endOfVF = _findEndOfULengthVF();
    int eLength = endOfVF - eStart;
    _rIndex = endOfVF + 8;
    Element e;
/*    if (code == kPixelData) {
      e = _makePixelData(eStart, eLength);
    } else {*/
    e = _makeAndAddElement(eStart, eLength);
    //   }
    log.debug1('$ree   ${elementInfo(e)} @end');
    log.up;
    return e;
  }

  Element _readPixelData(int eStart, int vfLength) {
    assert(_vrCode == VR.kOB.code || _vrCode == VR.kOW.code || _vrCode == VR.kUN.code);
    _pixelDataStart = _rIndex;
    _pixelDataVR = VR.lookup(_vrCode);
    log.debug('$rbb $_vr $_vrIndex readPixelData', 1);
    Element e;
    int item = _getUint32(_rIndex);
    log.debug2('$rmm   item($item, ${hex32(item)}');
    if (item == kItem32BitLE) {
      log.debug1('$rmm readFragmentedPixelData eStart($eStart)');
      e = _readFragmentedPixelData(eStart, vfLength);
    } else if (vfLength == kUndefinedLength) {
      log.debug1('$rmm read Undefined Pixel Data eStart($eStart)');
      int endOfVF = _findEndOfULengthVF();
      int eLength = endOfVF - eStart;
      _rIndex = endOfVF + 8;
      e = _makePixelData(eStart, eLength);
    } else {
      log.debug1('$rmm read Defined Pixel Data eStart($eStart)');
      _rIndex = _rIndex + vfLength;
      var eLength = _rIndex - eStart;
      e = _makePixelData(eStart, eLength);
    }
    _beyondPixelData = true;
    _pixelDataEnd = _rIndex;
    log.debug('$ree   ${elementInfo(e)} @end', -1);
    return e;
  }

  /// Reads an encapsulated (compressed) [kPixelData] [Element].
  Element _readFragmentedPixelData(int eStart, int vfLength) {
    log.debug(
        '$rbb readFragmentedPixelData vfLength($vfLength, '
        '${hex32(vfLength)}',
        1);
    if (_vrCode != VR.kOB.code && _vrCode != VR.kUN.code) {
      VR vr = VR.lookup(_vrCode);
      _warn('Invalid VR($vr) for Encapsulated TS: $_tsUid $_rrr');
      _hadParsingErrors = true;
    }
    var fragments = _readFragments();
    var eLength = _rIndex - eStart;
    var e = _makePixelData(eStart, eLength, fragments);
    log.debug('$ree   fragments: $fragments @end', -1);
    return e;
  }

  VFFragments _readFragments() {
    log.debug('$rbb readFragements', 1);
    var fragments = <Uint8List>[];
    int code = _readUint32();
    int fragNumber = 0;
    do {
      assert(code == kItem32BitLE, 'Invalid Item code: ${dcm(code)}');
      int vfLength = _readUint32();
      assert(vfLength != kUndefinedLength, 'Invalid length: ${dcm(vfLength)}');
      int startOfVF = _rIndex;
      _rIndex += vfLength;
      fragments.add(rootBD.buffer.asUint8List(startOfVF, _rIndex - startOfVF));
      fragNumber++;
      log.debug1('$rmm   fragment: $fragNumber, vfLength: $vfLength');
      code = _readUint32();
    } while (code != kSequenceDelimitationItem32BitLE);
    // Read the Sequence Delimitation Item length field.
    int vfLength = _readUint32();
    if (vfLength != 0)
      _warn('Pixel Data Sequence delimiter has non-zero '
          'value: $code/0x${hex32(code)} $_rrr');
    var vfFragments = new VFFragments(fragments);
    log.debug('$ree   $vfFragments @end', -1);
    return vfFragments;
  }

  Element _makePixelData(eStart, eLength, [VFFragments fragments]) {
    log.debug(
        '$rbb _makePixelData: $_vr '
        '$eStart - $eLength = ${eStart + eLength}, $fragments',
        1);
    var ebd = rootBD.buffer.asByteData(eStart, eLength);
    var e = makePixelData(_vrIndex, ebd, fragments);
    _add(e);
    assert(_checkRIndex());
    log.debug('$ree   fragments: $fragments @end', -1);
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
    assert(vrCode == VR.kUN.code);
    return (checkForUNSequence) ? _checkIfSequence(code, vrCode) : false;
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
    var v = (delimiter == kItem32BitLE || delimiter == kSequenceDelimitationItem32BitLE)
        ? true
        : false;
    log.debug2('$rmm       $v @end');
    return v;
  }

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem32Bit] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads a [kUndefinedLength] Sequence.
  Element _readUSQ(int code, int eStart, int vfLength) {
    assert(vfLength == kUndefinedLength);
    log.debug('$rbb readUSQ: ${_startSQ(code, eStart, vfLength)}', 1);
    // FIX: give this a type when understood.
    var items = [];
    while (!_isSequenceDelimiter()) {
      items.add(_readItem());
      _checkRIndex();
    }
    var sq = _makeSQ(code, eStart, items);
    _nDSequencesRead++;
    log.debug('$ree   $sq ${items.length} items @end', -1);
    return sq;
  }

  /// Reads a defined [vfLength].
  Element _readDSQ(int code, int eStart, int vfLength) {
    assert(vfLength != kUndefinedLength);
    log.debug('$rbb readDSQ: ${_startSQ(code, eStart, vfLength)}', 1);
    // FIX: give this a type when understood.
    var items = [];
    int eEnd = _rIndex + vfLength;
    while (_rIndex < eEnd) {
      items.add(_readItem());
      _checkRIndex();
    }
    var sq = _makeSQ(code, eStart, items);
    _nUSequencesRead++;
    log.debug('$ree  ${elementInfo(sq)} ${items.length} items readDS@ @end', -1);
    return sq;
  }

  Element _makeSQ(int code, int eStart, List items) {
    log.debug1('$rmm   makeSQ: $eStart - $items', 1);
    // Keep, but only use for debugging.
    //_showNext(_rIndex);
    int eLength = _rIndex - eStart;
    log.debug1('$rmm   eLength($eLength), makeSQ');

    var ebd = rootBD.buffer.asByteData(eStart, eLength);
    Element sq = makeSQ(ebd, currentDS, items, _vfLength, _isEVR);
    _add(sq);
    if (Tag.isPrivateCode(code)) _nPrivateSequencesRead++;
    _nSequencesRead++;
    log.debug1('$rmm   makeSQ @end', -1);
    return sq;
  }

  String _startSQ(int code, int eStart, int vfLength) => '${dcm(code)} eStart($eStart) '
      'vfLength ($vfLength, ${hex32(vfLength)})';

  /// Returns [true] if the sequence delimiter is found at [_rIndex].
  bool _isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  //TODO: put _checkIndex in appropriate places
  bool _checkRIndex() {
    if (_rIndex.isOdd) {
      var msg = 'Odd Lenth Value Field at @$_rIndex - incrementing';
      _warn('$msg $_rrr');
      _skip(1);
      _nOddLengthValueFields++;
      if (throwOnError) throw msg;
    }
    return true;
  }

  /// Returns [true] if the [kItemDelimitationItem32Bit] delimiter is found.
  bool _checkForItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

  final kItem = hex32(kItem32BitLE);

  /// Returns an [Item] or Fragment.
  Dataset _readItem() {
    assert(hasRemaining(8));
    int itemStart = _rIndex;
    // read 32-bit kItem code
    int delimiter = _readUint32();
    assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
    int vfLength = _readUint32();

    String actual = hex32(delimiter);
    log.debug(
        '$rbb readItem kItem($kItem), actual($actual) '
        '${toVFLength(vfLength)}',
        1);
    log.debug1('$rmm   ${toHadULength(vfLength)}');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    Dataset parentDS = currentDS;
    var parentMap = currentMap;
    var parentDupMap = duplicates;
    var map = <int, Element>{};
    var dupMap = <int, Element>{};
    currentMap = map;
    duplicates = dupMap;

    int itemEnd;
    try {
      if (vfLength == kUndefinedLength) {
        log.debug2('$rmm   Undefined Item length');
        while (!_checkForItemDelimiter()) {
          //   _add(_readElement());
          _lastElementRead = _readElement();
        }
        itemEnd = _rIndex;
      } else {
        itemEnd = _rIndex + vfLength;
        log.debug2('$rmm   Fixed Item length: itemEnd($itemEnd)');
        while (_rIndex < itemEnd) {
          //_add(_readElement());
          _lastElementRead = _readElement();
        }
      }
    } on EndOfDataError {
      log.debug('$ree   @end', -1);
      log.reset;
      rethrow;
    } catch (e) {
      _hadParsingErrors = true;
      _error(e);
      log.reset;
      rethrow;
    } finally {
      log.debug2('$rmm   item.length(${currentDS.length})');
      // Restore previous parent
      currentDS = parentDS;
      currentMap = parentMap;
      duplicates = parentDupMap;
      // Keep, but only use for debugging.
      //  _showNext(_rIndex);
    }
    var ibd = rootBD.buffer.asByteData(itemStart, itemEnd - itemStart);
    var item = makeItem(ibd, currentDS, vfLength, map, dupMap);
    _nItemsRead++;
    log.debug('$ree   ${itemInfo(item)} @end', -1);
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
    _warn('Encountered non-zero delimiter length($dLength) $_rrr');
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
    if (!_isReadable) {
      throw new EndOfDataError("_findEndOfVF");
    }
    int delimiterLength = _readUint32();
    if (delimiterLength != 0) _delimiterLengthWarning(delimiterLength);
    int endOfVF = _rIndex - 8;
    log.debug1('$ree   endOfVR($endOfVF) eEnd($_rIndex) @end');
    log.up;
    return endOfVF;
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
    return rootBD.getUint32(offset, Endianness.LITTLE_ENDIAN);
  }

  int _getUint16(int offset) {
    assert(offset.isEven);
    return rootBD.getUint16(offset, Endianness.LITTLE_ENDIAN);
  }

  int _getUint8(int offset) => rootBD.getUint8(offset);

  int _skip(int n) {
    assert(_rIndex.isEven);
    int index = _rIndex + n;
    _rIndex = RangeError.checkValidRange(0, index, rootBD.lengthInBytes);
    return _rIndex;
  }

  void _warn(String msg) {
    var s = '**   $msg $_rrr';
    exceptions.add(s);
    log.warn(s);
  }

  void _error(String msg) {
    var s = '**** $msg $_rrr';
    exceptions.add(s);
    log.error(s);
  }

//  String _readUtf8String(int length) => UTF8.decode(_readChars(length));

  // **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _rrr => 'R@$_rIndex';

  /// The beginning of reading an [Element] or [Item].
  String get rbb => '> $_rrr';

  /// In the middle of reading an [Element] or [Item]
  String get rmm => '| $_rrr  ';

  /// The end of reading an [Element] or [Item]
  String get ree => '< $_rrr  ';

  String get pad => "".padRight('$_rrr'.length);

  bool _checkAllZeros(int start, int end) {
    for (int i = start; i < end; i++) if (_getUint8(i) != 0) return false;
    return true;
  }

/* Enhancement:
  void _printTrailingData(int start, int length) {
    for (int i = start; i < start + length; i += 4) {
      var x = _getUint16(i);
      var y = _getUint16(i + 2);
      var z = _getUint32(i);
      var xx = toHex8(x);
      var yy = toHex16(y);
      var zz = hex32(z);
      print('@$i: 16($x, $xx) | $y, $yy) 32($z, $zz)');
    }
  }
*/

/*  Enhancement: Flush if not needed
  bool _doLog = true;


  String get _XCode => '${dcm(_code)}';
  String get _XvrCode => 'vrCode(${toHex16(_vrCode)})';
  String get _XvfLength => 'vfLength(${hex32(_vfLength)})';


  _start(String name, [int code, int start]) {
    if (!_doLog) return;
    log.debug('$rbb $name${dcm(code)} $_evrString ', 1);
  }

  _end(String name, Element e, [String msg]) {
    if (!_doLog) return;
    log.debug('$ree $_nElementsRead: $e @end', -1);
  }
*/

  //Enhancement: make this method do more diagnosis.
  /// Returns [true] if there are only trailing zeros at the end of the
  /// Object being parsed.
  Element _zeroEncountered(int code) {
    var msg = (_beyondPixelData) ? 'after kPixelData' : 'before kPixelData';
    _warn('Zero encountered $msg $_rrr');
    throw new EndOfDataError('Zero encountered $msg $_rrr');
  }

  // Issue:
  // **** Below this level is all for debugging and can be commented out for
  // **** production.

  void _showNext(int start) {
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
      log.debug('$rmm **** Short EVR: ${dcm(code)} $vr vfLength: $vfLength');
    }
  }

  void _showLongEVR(int start) {
    if (_hasRemaining(8)) {
      int code = _getCode(start);
      int vrCode = _getUint16(start + 4);
      VR vr = VR.lookup(vrCode);
      int vfLength = _getUint32(start + 8);
      log.debug('$rmm **** Long EVR: ${dcm(code)} $vr vfLength: $vfLength');
    }
  }

  void _showIVR(int start) {
    if (_hasRemaining(8)) {
      int code = _getCode(start);
      Tag tag = Tag.lookupByCode(code);
      if (tag != null) log.debug(tag);
      int vfLength = _getUint16(start + 4);
      log.debug('$rmm **** IVR: ${dcm(code)} vfLength: $vfLength');
    }
  }

  String get stats {
    var dsSQs = _getSequences(rootDS.map);
    var dupSQs = _getSequences(rootDS.dupMap);

    return '''$rmm Statistics
          nElementsRead: $_nElementsRead
         nSequencesRead: $_nSequencesRead
            nDSequences: $_nDSequencesRead
            nUSequences: $_nUSequencesRead
             nItemsRead: $_nItemsRead
   nPrivateElementsRead: $_nPrivateElementsRead
  nPrivateSequencesRead: $_nPrivateSequencesRead
lastTopLevelElementRead: $_lastTopLevelElementRead
        lastElementRead: $_lastElementRead
        lastElementCode: ${dcm(_lastElementCode)}
        bdLengthInBytes: ${rootBD.lengthInBytes}
        dsLengthInBytes: $_dsLengthInBytes
         endOfDataError: $_endOfDataError
           bytesUnread: $_bytesUnread
            rootDSTotal: ${rootDS.total}
         rootDSTopLevel ${rootDS.length}
        rootDSSequences: $dsSQs
        rootDSDupLength: ${rootDS.length}
        currentDSLength: ${currentMap.length}
     currentDSDupLength: ${duplicates.length}
     currentDSSequences: $dupSQs
                totalDS: ${rootDS.total + rootDS.dupTotal}''';
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

  String toVFLength(int vfl) => 'vfLength($vfl, ${hex32(vfl)})';
  String toHadULength(int vfl) =>
      'HadULength(${(vfl == kUndefinedLength) ? "true": "false"})';
}
