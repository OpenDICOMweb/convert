// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/element.dart';
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
	/// The source of the [Uint8List] being read.
  final String path;

  /// The [ByteData] being read.
  @override
  final ByteData rootBD;
  final bool async;
  final bool fast;
  final bool fmiOnly;

  /// If [true] and Preamble and Prefix are not present, abort reading.
  final bool allowMissingPrefix;

  /// If [true] and File Meta Information (FMI) is not present, abort reading.
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
  final List<String> exceptions = <String>[];

  /// Returns the [ByteData] that was actually read, i.e. from 0 to
  /// end of last [Element] read.
  ByteData bdRead;
  // ParseInfo values
  bool _isEVR;
  int _nElementsRead = 0;
  int _nSequencesRead = 0;
  int _nItemsRead = 0;
  int _nDSequencesRead = 0;
  int _nUSequencesRead = 0;
  int _nPrivateElementsRead = 0;
  int _nPrivateSequencesRead = 0;

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

  bool _wasShortFile;
  bool _hadTrailingBytes = false;
  bool _hadTrailingZeros = false;
  var _bytesUnread = 0;

  /// The current read index.
  var _rIndex = 0;

  /// Creates a new [DcmReader]  where [_rIndex] = writeIndex = 0.
  DcmReader(this.rootBD,
      {this.path = '',
      this.async = true,
      this.fast: true,
      this.fmiOnly = false,
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
    //  log.debug('ByteData length: ${rootBD.lengthInBytes}');
    if (_wasShortFile) {
      final s = 'Short file error: length(${rootBD.lengthInBytes}) $path';
      _warn('$s $_rrr');
      if (throwOnError) throw new ShortFileError('Length($rootBD.lengthInBytes) $path');
    }
  }

  ElementList  _elements;
  bool get isEVR => _isEVR;

  bool get _isReadable => _rIndex < rootBD.lengthInBytes;

  bool get isReadable => _isReadable;

  bool _hasRemaining(int n) => (_rIndex + n) <= rootBD.lengthInBytes;

  bool hasRemaining(int n) => _hasRemaining(n);

  Uint8List get buffer =>
      rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  Uint8List get rootBytes =>
      rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  ParseInfo getParseInfo() => new ParseInfo(
      _nElementsRead,
      _nSequencesRead,
      _nPrivateElementsRead,
      _nPrivateSequencesRead,
      rootDS.total,
      rootDS.length,
      rootDS.elements.duplicates.length,
      0,
      0,
      0,
      path,
      _preamble,
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
      exceptions,
      isEVR: isEVR,
      wasShortFile: _wasShortFile,
      hadFmi: _hadFmi,
      hadPrefix: _hadPrefix,
      preambleWasZeros: _preambleWasZeros,
      hadParsingErrors: _hadParsingErrors,
      hadGroupLengths: _hadGroupLengths,
      hadTrailingBytes: _hadTrailingBytes,
      hadTrailingZeros: _hadTrailingZeros);

  bool dcmReadFMI({bool checkPreamble = true, bool allowMissingPrefix = false}) {
    currentDS = rootDS;
    return _readFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
  }

  /// Reads a Root [Dataset] from [this] and returns it.
  /// If an error is encountered and [system].throwOnError is [true],
  /// an Error will be thrown; otherwise, returns [null].
  RootDataset dcmReadRootDataset(
      {bool allowMissingFMI = false,
      bool checkPreamble = true,
      bool allowMissingPrefix = false}) {
    currentDS = rootDS;
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

    try {
      currentDS = rootDS;
      //  log.debug1('$rbb readDataset: isExplicitVR(${_isEVR})');
      while (_hasRemaining(8)) _readElement();
      //  log.debug1('$ree end readDataset: isExplicitVR(${_isEVR})');
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

    //  log.debug1(stats);
    if (_rIndex != bdRead.lengthInBytes) {
      _warn('End of Data with _rIndex($_rIndex) != bdRead.length'
          '(${bdRead.lengthInBytes}) $_rrr');
      _dsLengthInBytes = _rIndex;
      _endOfLastValueRead = _rIndex;
      _hadTrailingBytes = (bdRead.lengthInBytes != rootBD.lengthInBytes);
      if (_hadTrailingBytes)
        _hadTrailingZeros = _checkAllZeros(_rIndex, rootBD.lengthInBytes);
    }

    final rootDSTotal = rootDS.total + rootDS.dupTotal;
    if (_nElementsRead != rootDSTotal) {
      final msg = 'Inconsistent Elements Error: '
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
      final chars = rootBD.buffer.asUint8List(_rIndex, 4);
      _rIndex += 4;
      return ASCII.decode(chars);
    }

    try {
      var msg = '';
      if (_rIndex != 0) msg += 'Attempt to read DICOM Prefix at ByteData[$_rIndex]\n';
      if (_hadPrefix != null) msg += 'Attempt to re-read DICOM Preamble and Prefix.\n';
      if (rootBD.lengthInBytes <= 132)
        msg += 'ByteData length(${rootBD.lengthInBytes}) < 132';
      if (msg.isNotEmpty) {
        _error(msg);
        return false;
      }
      if (checkPreamble) {
        _preambleWasZeros = true;
        _preamble = rootBD.buffer.asUint8List(0, 128);
        for (var i = 0; i < 128; i++)
          if (rootBD.getUint8(i) != 0) _preambleWasZeros = false;
      }
      _skip(128);

      final prefix = readAsciiPrefix();
      final v = (prefix == 'DICM') ? true : false;
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
    //  log.debug('$rbb readFmi($currentDS)', -1);
    assert(_hadPrefix == null);
    _hadPrefix = _readPrefix(checkPreamble);
    if (!_hadPrefix && !allowMissingPrefix) {
      //  log.debug('$ree  No Prefix', 1);
      return false;
    }
    //  log.debug1('$rmm readFMI: prefix($_hadPrefix) $rootDS');
    final eStart = _rIndex;
    int code;
    try {
      while (_isReadable) {
        code = _peekTagCode();
        if (code >= 0x00030000) break;
        _readElement();
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hadParsingErrors = true;
      _warn('Failed to read FMI: "$path"\nException: $x\n $_rrr');
      _warn('  File length: ${rootBD.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = 0;
      //  log.debug('$ree readFMI Invalid TS catch: $x', -1);
      rethrow;
    } catch (x) {
      if (code == 0) _zeroEncountered(code);
      _hadParsingErrors = true;
      _error('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${rootBD.lengthInBytes}\n$ree readFMI catch: $x');
      _rIndex = eStart;
      //  log.debug('$ree readFMI Catch: $x', -1);
      rethrow;
    }
    if (!isReadable) {
      throw new EndOfDataError('_readFMI');
    }
    _hadFmi = true;

    //  Fmi fmi = new Fmi(rootDS);
    //  _tsUid = fmi.transferSyntax;
    _tsUid = rootDS.transferSyntax;
    _isEVR = !_tsUid.isImplicitLittleEndian;
/*
    Uid mediaStorageSopClass =
        rootDS.getUidByTag(PTag.kMediaStorageSOPClassUID, aType: AType.k1);
    Uid mediaStorageSopInstance =
        rootDS.getUidByTag(PTag.kMediaStorageSOPInstanceUID, aType: AType.k1);
*/

/* remove
    //TODO: use _ts or tsUid not both
    // Get TS or if not present use default
    _tsUid = rootDS.transferSyntax;
    if (_tsUid == null) _tsUid = system.defaultTransferSyntax;
    _isEVR = !_tsUid.isImplicitLittleEndian;
*/

/*
     _tsUid = rootDS.getUidByTag(PTag.kTransferSyntaxUID, aType: AType.k1);
    if (_tsUid == null) {
      missingRequiredElementError(PTag.kTransferSyntaxUID);
      log.info0('Using system.defaultTransferSyntax: ${system.defaultTransferSyntax}');
      _tsUid = system.defaultTransferSyntax;
    }
    _isEVR = !_tsUid.isImplicitLittleEndian;
*/

/*
    Uid implementationClass =
        rootDS.getUidByTag(PTag.kImplementationClassUID, aType: AType.k1);
    Uid implementationVersion =
        rootDS.getUidByTag(PTag.kImplementationVersionName, aType: AType.k3);
    String sourceAppAETitle =
        rootDS.getStringByTag(PTag.kSourceApplicationEntityTitle, aType: AType.k3);
    String sendingAppAETitle =
        rootDS.getStringByTag(PTag.kSendingApplicationEntityTitle, aType: AType.k3);
    String receivingAppAETitle =
        rootDS.getStringByTag(PTag.kReceivingApplicationEntityTitle, aType: AType.k3);
    Uid privateInfoCreatorUid =
        rootDS.getUidByTag(PTag.kPrivateInformationCreatorUID, aType: AType.k3);
    Uint8List privateInfo =
        rootDS.getIntListByTag(PTag.kPrivateInformation, aType: AType.k3);
*/

    //  log.debug1('$rmm isExplicitVR: $_isEVR');
    //  log.debug('$rmm TS:${_ts}');
    //  log.debug1('$rmm targetTS: $targetTS');
    //  log.debug('$ree readFmi: ${rootDS.info}', 1);
    return true;
  }

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => _hadPrefix != null;

/*
  /// Returns a [String] indicating whether VR is Explicit or Implicit.
  String get _evrString => (_isEVR) ? 'EVR' : 'IVR';
*/

  /// All [Elements are read by this method.
  Element _readElement() {
    final eStart = _rIndex;
    final code = _readTagCode();
    if (code == 0) {
      _skip(-4); // undo readTagCode
      _zeroEncountered(code);
      return null;
    }
    final vfLengthFieldField = (_isEVR) ? _readEVRHdr(code, eStart) : _readIVRHdr(code, eStart);
    assert(_vr != null, 'Invalid null VR: vrCode(${hex16(_vrCode)})');
    Element e;
    if (code == kPixelData) {
      e = _readPixelData(eStart, vfLengthFieldField);
    } else if (vfLengthFieldField == kUndefinedLength) {
      e = _readULength(code, eStart, vfLengthFieldField);
    } else {
      e = _readDLength(code, eStart, vfLengthFieldField);
    }

    //Enhancement: only gather statistics when statisticsEnables is true
    // Statistics
    if (statisticsEnabled) {
      _nElementsRead++;
      _endOfLastValueRead = _rIndex;
// TODO: convert to ELementOffsets      
//      if (elementListEnabled) elementList.add(eStart, _rIndex, e);
      _lastTopLevelElementRead = e;
      _lastElementCode = code;
      if ((code >> 16).isOdd) _nPrivateElementsRead++;
    }
    // For debugging only
    _tagCode = code;
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
  void _add(Element eNew) => currentDS.elements.add(eNew);
		  
/*
  void _add(Element eNew) {
    final v = elements.lookup(eNew.index);
    if (v == null) {
      // Urgent: add check for valid values with switch
      elements[eNew.index] = eNew;
    } else if (allowDuplicates && v != null) {
      _warn('Duplicate Element: current($v) duplicat(${elementInfo(eNew)}) $_rrr');
      if (v.vr != VR.kUN) {
        duplicates[eNew.index] = eNew;
      } else {
        elements[eNew.index] = eNew;
        duplicates[eNew.index] = v;
      }
    } else {
      if (throwOnError) throw new DuplicateElementError(v, eNew);
    }
  }
*/

  // The current tag code, tag, VR code, VR, and VR Index.
  int _tagCode;
  Tag _tag;
  int _vrCode;
  VR _vr;
  int _vrIndex;
  int _vfLengthField;

  int _readEVRHdr(int code, int eStart) {
    _vrCode = _readUint16();
    _vr = VR.lookup(_vrCode);
    _vrIndex = _vr.index;
    if (_vr == null) {
      _warn('VR is Null: _vrCode(${hex16(_vrCode)}) $_rrr');
      _showNext(_rIndex - 4);
    }
    if (decoding.doCheckVR) _checkVR(code, _vrCode);
    if (_vr.hasShortVF) {
      _vfLengthField = _readUint16();
    } else {
      _skip(2);
      _vfLengthField = _readUint32();
    }
    assert(_checkRIndex());
    //TODO: add a statistics collector here recording frequency of code, vr, vfLengthFieldField
    return _vfLengthField;
  }

  //TODO: add VR.kSSUS, etc. to dictionary
  /// checks that code & vrCode are
  void _checkVR(int code, int vrCode, [bool warnOnUN = false]) {
    final tag = Tag.lookupByCode(code);
    if (tag == null) {
      _warn('Unknown Tag Code(${dcm(code)}) $_rrr');
    } else if (vrCode == VR.kUN.code && tag.vr != VR.kUN) {
      //Enhancement remove PTags with VR.kUN and add multi-values VRs
      _warn('${dcm(code)} VR.kUN($vrCode) should be ${tag.vr} $_rrr');
      _vrCode = tag.vr.code;
    } else if (vrCode != VR.kUN.code && tag.vr.code == VR.kUN.code) {
      if (code != kPixelData && warnOnUN == true) {
        if (tag is PDTag && tag is! PDTagKnown) {
          log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Data');
        } else if (tag is PCTag && tag is! PCTagKnown) {
          log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Creator $tag');
        } else {
          log.info0('$pad ${dcm(code)} VR.kUN: $tag');
        }
      }
    } else if (vrCode != VR.kUN.code && vrCode != tag.vr.code) {
      final vr0 = VR.lookup(vrCode);
      _warn('${dcm(code)} Wrong VR $vr0($vrCode) '
          'should be ${tag.vr} $_rrr');
    }
    _tag = tag;
  }

  int _readIVRHdr(int code, int eStart) {
    if (doConvertUndefinedVR) {
      _tag = Tag.lookupByCode(code);
      _vr = (_tag == null) ? VR.kUN : _tag.vr;
    } else {
      _vr = VR.kUN;
    }
    _vrCode = _vr.code;
    _vrIndex = _vr.index;
    _vfLengthField = _readUint32();
    //   _maker = IVR.maker;
    assert(_checkRIndex());
    return _vfLengthField;
  }

  // Read an [Element] with a defined length.
  Element _readDLength(int code, int eStart, int vfLengthFieldField) {
    //  log.debug2('$rmm   readDLength: ${dcm(code)} s:$eStart vfl: $vfLengthFieldField');
    Element e;
    if (_isSequence(code, _vrCode)) {
      //  log.debug2('$rmm     DLength Sequence');
      e = _readDSQ(code, eStart, vfLengthFieldField);
    } else if (vfLengthFieldField == 0) {
      //  log.debug2('$rmm     DLength Empty Element');
      e = _makeAndAddElement(eStart, _rIndex - eStart);
    } else {
      //  log.debug2('$rmm     Simple DLength ');
      e = _readSimpleDLength(code, eStart, vfLengthFieldField);
    }
    //  log.debug2('$rmm     ${show(e)} @end');
    assert(_checkRIndex());
    return e;
  }

  Element _readSimpleDLength(int code, int eStart, int vfLengthFieldField) {
    log.down;
    //  log.debug1('$rbb  readSimpleDLength');
    Element e;
    if (code > 0x3000 && Tag.isGroupLengthCode(code)) _hadGroupLengths = true;
    _rIndex = _rIndex + vfLengthFieldField;
    final eLength = _rIndex - eStart;
    e = _makeAndAddElement(eStart, eLength);
    //   }
    //  log.debug1('$ree   ${show(e)} @end');
    log.up;
    return e;
  }

  Element _makeAndAddElement(int eStart, int eLength) {
    final ebd = rootBD.buffer.asByteData(eStart, eLength);
    final e = makeElement(_tag.vrIndex, _tag, ebd, _vfLengthField);
    _add(e);
    return e;
  }

  /// Read an [Element] with [kUndefinedLength] Value Length Field.
  Element _readULength(int code, int eStart, int vfLengthFieldField) {
    log.down;
    //  log.debug2('$rbb readULength code${dcm(code)} eStart($eStart)');
    assert(vfLengthFieldField == kUndefinedLength);
    Element e;
    if (_isSequence(code, _vrCode)) {
      //  log.debug2('$rmm   ULength Sequence(${dcm(code)}');
      e = _readUSQ(code, eStart, vfLengthFieldField);
/*    } else if (code == kPixelData) {
      //  log.debug2('$rmm   ULength Pixel Data(${dcm(code)}');
      e = _readFragmentedPixelData(eStart, vfLengthFieldField);*/
    } else {
      //  log.debug2('$rmm   Simple ULength element(${dcm(code)}');
      e = _readSimpleULength(code, eStart, vfLengthFieldField);
    }
    assert(_checkRIndex());
    //  log.debug2('$ree ${show(e)}   @end');
    log.up;
    return e;
  }

  /// Read a simple Undefined Length [Element], i.e. not a [Sequence],
  /// and not an encapsulated [kPixelData].
  Element _readSimpleULength(int code, int eStart, int vfLengthFieldField) {
    assert(vfLengthFieldField == kUndefinedLength);
    log.down;
    //  log.debug1('$rbb readSimpleULength code(${dcm(code)}eStart($eStart)');
    final endOfVF = _findEndOfULengthVF();
    final eLength = endOfVF - eStart;
    _rIndex = endOfVF + 8;
    Element e;
/*    if (code == kPixelData) {
      e = _makePixelData(eStart, eLength);
    } else {*/
    e = _makeAndAddElement(eStart, eLength);
    //   }
    //  log.debug1('$ree   ${show(e)} @end');
    log.up;
    return e;
  }

  Element _readPixelData(int eStart, int vfLengthFieldField) {
    assert(_vrCode == VR.kOB.code || _vrCode == VR.kOW.code || _vrCode == VR.kUN.code);
    _pixelDataStart = _rIndex;
    _pixelDataVR = VR.lookup(_vrCode);
    //  log.debug('$rbb $_vr $_vrIndex readPixelData', 1);
    Element e;
    final item = _getUint32(_rIndex);
    //  log.debug2('$rmm   item($item, ${hex32(item)}');
    if (item == kItem32BitLE) {
      //  log.debug1('$rmm readFragmentedPixelData eStart($eStart)');
      e = _readFragmentedPixelData(eStart, vfLengthFieldField);
    } else if (vfLengthFieldField == kUndefinedLength) {
      //  log.debug1('$rmm read Undefined Pixel Data eStart($eStart)');
      final endOfVF = _findEndOfULengthVF();
      final eLength = endOfVF - eStart;
      _rIndex = endOfVF + 8;
      e = _makePixelData(eStart, eLength);
    } else {
      //  log.debug1('$rmm read Defined Pixel Data eStart($eStart)');
      _rIndex = _rIndex + vfLengthFieldField;
      final eLength = _rIndex - eStart;
      e = _makePixelData(eStart, eLength);
    }
    _beyondPixelData = true;
    _pixelDataEnd = _rIndex;
    //  log.debug('$ree   ${show(e)} @end', -1);
    return e;
  }

  /// Reads an encapsulated (compressed) [kPixelData] [Element].
  Element _readFragmentedPixelData(int eStart, int vfLengthFieldField) {
/*    log.debug(
        '$rbb readFragmentedPixelData vfLengthField($vfLengthField, '
        '${hex32(vfLengthFieldField)}',
        1);*/
    if (_vrCode != VR.kOB.code && _vrCode != VR.kUN.code) {
      final vr = VR.lookup(_vrCode);
      _warn('Invalid VR($vr) for Encapsulated TS: $_tsUid $_rrr');
      _hadParsingErrors = true;
    }
    final fragments = _readFragments();
    final eLength = _rIndex - eStart;
    final e = _makePixelData(eStart, eLength, fragments);
    return e;
  }

  VFFragments _readFragments() {
    //  log.debug('$rbb readFragements', 1);
    final fragments = <Uint8List>[];
    var code = _readUint32();
    do {
      assert(code == kItem32BitLE, 'Invalid Item code: ${dcm(code)}');
      final vfLengthFieldField = _readUint32();
      assert(vfLengthFieldField != kUndefinedLength, 'Invalid length: ${dcm(vfLengthFieldField)}');
      final startOfVF = _rIndex;
      _rIndex += vfLengthFieldField;
      fragments.add(rootBD.buffer.asUint8List(startOfVF, _rIndex - startOfVF));
      code = _readUint32();
    } while (code != kSequenceDelimitationItem32BitLE);
    // Read the Sequence Delimitation Item length field.
    final vfLengthFieldField = _readUint32();
    if (vfLengthFieldField != 0)
      _warn('Pixel Data Sequence delimiter has non-zero '
          'value: $code/0x${hex32(code)} $_rrr');
    return new VFFragments(fragments);
  }

  Element _makePixelData(int eStart, int eLength, [VFFragments fragments]) {
    final ebd = rootBD.buffer.asByteData(eStart, eLength);
    final e = makePixelData(_vrIndex, ebd, fragments);
    _add(e);
    assert(_checkRIndex());
    //  log.debug('$ree   fragments: $fragments @end', -1);
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
    assert((_isEVR && vrCode == VR.kUN.code) || !_isEVR);
    if (code == kPixelData) return false;
    final delimiter = _getUint32(_rIndex);
    final v = (delimiter == kItem32BitLE || delimiter == kSequenceDelimitationItem32BitLE)
        ? true
        : false;
    return v;
  }

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem32Bit] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // reading the value field of these [Element]s. Returns an [SQ] [Element].

  /// Reads a [kUndefinedLength] Sequence.
  Element _readUSQ(int code, int eStart, int vfLengthFieldField) {
    assert(vfLengthFieldField == kUndefinedLength);
    //  log.debug('$rbb readUSQ: ${_startSQ(code, eStart, vfLengthField)}', 1);
    // FIX: give this a type when understood.
    final items = <Dataset>[];
    while (!_isSequenceDelimiter()) {
      items.add(_readItem());
      _checkRIndex();
    }
    final sq = _makeSQ(code, eStart, items);
    _nDSequencesRead++;
    //  log.debug('$ree   $sq ${items.length} items @end', -1);
    return sq;
  }

  /// Reads a defined [vfLengthField].
  Element _readDSQ(int code, int eStart, int vfLengthField) {
    assert(vfLengthField != kUndefinedLength);
    //  log.debug('$rbb readDSQ: ${_startSQ(code, eStart, vfLengthField)}', 1);
    // FIX: give this a type when understood.
    final items = <Dataset>[];
    final eEnd = _rIndex + vfLengthField;
    while (_rIndex < eEnd) {
      items.add(_readItem());
      _checkRIndex();
    }
    final sq = _makeSQ(code, eStart, items);
    _nUSequencesRead++;
    //  log.debug('$ree  ${show(sq)} ${items.length} items readDS@ @end', -1);
    return sq;
  }

  Element _makeSQ(int code, int eStart, List items) {
    //  log.debug1('$rmm   makeSQ: $eStart - $items', 1);
    // Keep, but only use for debugging.
    //_showNext(_rIndex);
	  final eLength = _rIndex - eStart;
    //  log.debug1('$rmm   eLength($eLength), makeSQ');

	  final ebd = rootBD.buffer.asByteData(eStart, eLength);
    final sq = makeSQ(ebd, currentDS, items, _vfLengthField, _isEVR);
    _add(sq);
    if (Tag.isPrivateCode(code)) _nPrivateSequencesRead++;
    _nSequencesRead++;
    //  log.debug1('$rmm   makeSQ @end', -1);
    return sq;
  }

/*
  String _startSQ(int code, int eStart, int vfLengthField) =>
      '${dcm(code)} eStart($eStart) vfLengthField ($vfLengthField, ${hex32(vfLengthField)})';
*/

  /// Returns [true] if the sequence delimiter is found at [_rIndex].
  bool _isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

  //TODO: put _checkIndex in appropriate places
  bool _checkRIndex() {
    if (_rIndex.isOdd) {
      final msg = 'Odd Lenth Value Field at @$_rIndex - incrementing';
      _warn('$msg $_rrr');
      _skip(1);
      _nOddLengthValueFields++;
      if (throwOnError) throw msg;
    }
    return true;
  }

  /// Returns [true] if the [kItemDelimitationItem32Bit] delimiter is found.
  bool _checkForItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

  final String kItem = hex32(kItem32BitLE);

  /// Returns an [Item] or Fragment.
  Dataset _readItem() {
    assert(hasRemaining(8));
    final itemStart = _rIndex;
    // read 32-bit kItem code
    final delimiter = _readUint32();
    assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
    final vfLengthField = _readUint32();

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    final RootDataset parentDS = currentDS;
    final eListParent = currentDS.elements;
    _elements = new MapAsList();
 

    int itemEnd;
    try {
      if (vfLengthField == kUndefinedLength) {
        //  log.debug2('$rmm   Undefined Item length');
        while (!_checkForItemDelimiter()) {
          //   _add(_readElement());
          _lastElementRead = _readElement();
        }
        itemEnd = _rIndex;
      } else {
        itemEnd = _rIndex + vfLengthField;
        //  log.debug2('$rmm   Fixed Item length: itemEnd($itemEnd)');
        while (_rIndex < itemEnd) {
          //_add(_readElement());
          _lastElementRead = _readElement();
        }
      }
    } on EndOfDataError {
      //  log.debug('$ree   @end', -1);
      log.reset;
      rethrow;
    } catch (e) {
      _hadParsingErrors = true;
      _error(e);
      log.reset;
      rethrow;
    } finally {
      //  log.debug2('$rmm   item.length(${currentDS.length})');
      // Restore previous parent
      currentDS = parentDS;
      _elements = eListParent;
      //duplicates = currentDS.dupTotal;
      // Keep, but only use for debugging.
      //  _showNext(_rIndex);
    }
    final ibd = rootBD.buffer.asByteData(itemStart, itemEnd - itemStart);
    final item = makeItemFromList(currentDS, _elements, vfLengthField, ibd);
    _nItemsRead++;
    //  log.debug('$ree   ${showItem(item)} @end', -1);
    return item;
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_rIndex] is advanced past the Value Length Field;
  /// otherwise, readIndex does not change
  bool _checkForDelimiter(int target) {
    final delimiter = _getUint32(_rIndex);
    if (delimiter == target) {
      _skip(4);
      final delimiterLength = _readUint32();
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
    //  log.debug1('$rbb findEndOfULengthVF');
    while (_isReadable) {
      if (_readUint16() != kDelimiterFirst16Bits) continue;
      if (_readUint16() != kSequenceDelimiterLast16Bits) continue;
      break;
    }
    if (!_isReadable) {
      throw new EndOfDataError('_findEndOfVF');
    }
    final delimiterLength = _readUint32();
    if (delimiterLength != 0) _delimiterLengthWarning(delimiterLength);
    final endOfVF = _rIndex - 8;
    //  log.debug1('$ree   endOfVR($endOfVF) eEnd($_rIndex) @end');
    log.up;
    return endOfVF;
  }

  /// Reads a group and element and combines them into a Tag.code.
  int _readTagCode() {
    assert(_rIndex.isEven);
    final code = _peekTagCode();
    _rIndex += 4;
    return code;
  }

  /// Peek at next tag - doesn't move the [_rIndex].
  int _peekTagCode() {
    assert(_rIndex.isEven);
    final group = _getUint16(_rIndex);
    final elt = _getUint16(_rIndex + 2);
    return (group << 16) + elt;
  }

  int _readUint16() {
    assert(_rIndex.isEven);
    final v = _getUint16(_rIndex);
    _rIndex += 2;
    return v;
  }

  int _readUint32() {
    assert(_rIndex.isEven);
    final v = _getUint32(_rIndex);
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
    final index = _rIndex + n;
    return RangeError.checkValidRange(0, index, rootBD.lengthInBytes);
  }

  void _warn(String msg) {
    final s = '**   $msg $_rrr';
    exceptions.add(s);
    log.warn(s);
  }

  void _error(String msg) {
    final s = '**** $msg $_rrr';
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

  String get pad => ''.padRight('$_rrr'.length);

  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (_getUint8(i) != 0) return false;
    return true;
  }

/* Enhancement:
  void _printTrailingData(int start, int length) {
    for (var i= start; i < start + length; i += 4) {
      final x = _getUint16(i);
      final y = _getUint16(i + 2);
      final z = _getUint32(i);
      final xx = toHex8(x);
      final yy = toHex16(y);
      final zz = hex32(z);
      print('@$i: 16($x, $xx) | $y, $yy) 32($z, $zz)');
    }
  }
*/

/*  Enhancement: Flush if not needed
  bool _doLog = true;


  String get _XCode => '${dcm(_code)}';
  String get _XvrCode => 'vrCode(${toHex16(_vrCode)})';
  String get _XvfLengthField => 'vfLengthField(${hex32(_vfLengthField)})';


  _start(String name, [int code, int start]) {
    if (!_doLog) return;
    //  log.debug('$rbb $name${dcm(code)} $_evrString ', 1);
  }

  _end(String name, Element e, [String msg]) {
    if (!_doLog) return;
    //  log.debug('$ree $_nElementsRead: $e @end', -1);
  }
*/

  //Enhancement: make this method do more diagnosis.
  /// Returns [true] if there are only trailing zeros at the end of the
  /// Object being parsed.
  Element _zeroEncountered(int code) {
    final msg = (_beyondPixelData) ? 'after kPixelData' : 'before kPixelData';
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
      final group = _getUint16(start);
      final elt = _getUint16(start);
      return group << 16 & elt;
    }
    return null;
  }

  void _showShortEVR(int start) {
    if (_hasRemaining(8)) {
      final code = _getCode(start);
      final vrCode = _getUint16(start + 4);
      final vr = VR.lookup(vrCode);
      final vfLengthField = _getUint16(start + 6);
      log.debug('$rmm **** Short EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
    }
  }

  void _showLongEVR(int start) {
    if (_hasRemaining(8)) {
      final code = _getCode(start);
      final vrCode = _getUint16(start + 4);
      final vr = VR.lookup(vrCode);
      final vfLengthField = _getUint32(start + 8);
      log.debug('$rmm **** Long EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
    }
  }

  void _showIVR(int start) {
    if (_hasRemaining(8)) {
      final code = _getCode(start);
      final tag = Tag.lookupByCode(code);
      if (tag != null) log.debug(tag);
      final vfLengthField = _getUint16(start + 4);
      log.debug('$rmm **** IVR: ${dcm(code)} vfLengthField: $vfLengthField');
    }
  }

  String get stats => '''$rmm Statistics
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
        rootDSSequences: ${rootDS.elements.sequences}
        rootDSDupLength: ${rootDS.elements.duplicates.length}
        currentDSLength: ${rootDS.elements.length}
     currentDSDupLength: ${duplicates.length}
     currentDSSequences: ${currentDS.elements.sequences}
                totalDS: ${rootDS.total + rootDS.dupTotal}''';

  String toVFLength(int vfl) => 'vfLengthField($vfl, ${hex32(vfl)})';
  String toHadULength(int vfl) =>
      'HadULength(${(vfl == kUndefinedLength) ? 'true': 'false'})';
}
