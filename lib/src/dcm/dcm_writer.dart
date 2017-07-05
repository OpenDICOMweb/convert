// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

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
import 'package:dictionary/dictionary.dart';

const List<int> _undefinedLengthElements = const <int>[
  kSQCode,
  kOBCode,
  kOWCode,
  kUNCode
];

//TODO: remove log.debug when working
//TODO: rewrite all comments to reflect current state of code

/// A library for encoding [Dataset]s in the DICOM File Format.
///
/// Supports encoding all LITTLE ENDIAN [TransferSyntax]es.
/// Does not support BIG ENDIAN which is retired.
///
/// _Notes_:
///   1. In all cases DcmWriter writes the Value Fields as they
///   are in the data; thus, all Value Fields should have an even length.
///   2. All String manipulation should be handled in the attribute itself.
// There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN].
abstract class DcmWriter {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.debug2);

  //Urgent: this should grow and shrink automatically
  static const int defaultBufferLength = 200 * kMB;
  static ByteData _reuse;

  /// The target of the [Uint8List] being written.
  final String path;

  /// The [TransferSyntax] for the output.
  final TransferSyntax outputTS;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// if [true] [Dataset]s will be allowed to be written in IVRLE.
  final bool allowImplicitLittleEndian;

  //TODO: is this and addMissingFMI both necessary.
  /// If [true], a DICOM File Prefix (PS3.10) will be written even
  /// if it wasn't present when the [Dataset] was decoded (parsed).
  final bool addMissingPrefix;

  final bool addCleanPrefix;

  final bool allowMissingFMI;

  /// If [true], a DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when the [Dataset] was decoded (parsed).
  final bool addMissingFMI;

  final bool removeUndefinedLengths;

  final bool reUseBD;

  /// The [ByteData] buffer being written.
  final ByteData bd;

  /// The length in bytes of the [ByteData] buffer created.
  final int bdLength;

  final List<int> elementIndex = new List<int>(2000);
  int nthElement = 0;

  /// The current dataset.  This changes as Sequences are written.
  Dataset _currentDS;

  bool _isEVR;
  TransferSyntax _ts;
  bool _isEncapsulated;
  int _wIndex = 0;

  int _nElements = 0;
  int _nSequences = 0;
  int _nPrivateElements = 0;
  int _nPrivateSequences = 0;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmByteWriter]  where [_wIndex] = [writeIndex] = 0.
  DcmWriter(
    this.bdLength, {
    this.path = "",
    this.outputTS,
    this.throwOnError = true,
    this.allowImplicitLittleEndian = true,
    this.addMissingPrefix = false,
    this.addCleanPrefix = false,
    this.allowMissingFMI = false,
    this.addMissingFMI = false,
    this.removeUndefinedLengths = false,
    this.reUseBD = true,
  })
      : _wIndex = 0,
        bd = (reUseBD) ? _reuseBD(bdLength) : new ByteData(bdLength);

  int get endOfBD => bd.lengthInBytes;
  int get wIndex => _wIndex;
  bool get _isWritable => _wIndex < endOfBD;
  bool get isWriteable => _isWritable;

/* Flush when working
  bool _hasRemaining(int n) {
    if ((_wIndex + n) >= bd.lengthInBytes) _endOfBDError(_wIndex + n);
    return true;
  }
*/

  // **** Interface:
  /// The root Dataset being encoded.
  Dataset get rootDS;

  /// The current dataset.  This changes as Sequences are encoded.
  Dataset get currentDS => _currentDS;
  void set currentDS(Dataset ds) => _currentDS = ds;

  /// Returns [info] about [this].
  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Write only the FMI, and returns only the bytes that were written.
  Uint8List writeFMI() {
    _writeFMI();
    return bd.buffer.asUint8List(0, _wIndex);
  }

  /// Writes the [rootDS] [Dataset] to a Uint8List and returns the [Uint8List].
  Uint8List writeRootDataset() {
    log.debug('$wbb writeRootDataset: $rootDS');
    _currentDS = rootDS;
    _ts = rootDS.transferSyntax;
    _isEncapsulated = rootDS.transferSyntax.isEncapsulated;
    _isEVR = rootDS.isEVR;
    log.debug(
        '$wmm TransferSyntax(${_ts.name}), isEncapsulated($_isEncapsulated)');

    if (!allowMissingFMI && !rootDS.hasFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return null;
    }

    if (rootDS.parseInfo.hadPrefix || addMissingPrefix) _writePrefix();
    // Writes the FMI as normal elements
    // TODO: this does not add missing FMI elements
    _writeDataset(rootDS);
    log.debug('$wmm _nElements: $_nElements');
    log.debug('$wmm _nSequences: $_nSequences');
    log.debug('$wmm _nPrivateElements: $_nPrivateElements');
    log.debug('$wmm _nPrivateSequences: $_nPrivateSequences');
    log.debug('$wmm writeRootDataset: ${rootDS.info}');
    log.debug('$wee Returning ${rootDS.length} elements in ${_wIndex} bytes');
    var bytes = bd.buffer.asUint8List(0, _wIndex);
    if (bytes == null || bytes.length < 256)
      throw 'Invalid bytes error: $bytes';
    log.info('wrote ${bytes.length} bytes to "$path"');
    return bytes;
  }

  /// Testing interface
  void writeDataset(Dataset ds) => _writeDataset(ds);

  /// Testing interface
  void writeElement(Element e) => _writeElement(e);

  /// Writes File Meta Information ([Fmi]) to the output.
  void _writeFMI() {
    if (_currentDS != rootDS) log.error('Not rootDS');
    log.debugDown('$wbb writeFmi($_currentDS)');
    if (rootDS.parseInfo.hadPrefix || addMissingPrefix) _writePrefix();
    for (Element e in rootDS.elements) {
      while (e.code < 0x00030000) {
        _writeElement(e);
        log.debug2('$wmm writeFMI loop: $e');
      }
      break;
    }
    log.debugUp('$wee writeFmi end');
  }

  /// If the [RootDataset] was parsed and had a prefix then it was all zeros
  /// or not.
  void _writePrefix() {
    log.down;
    log.debug2('$wbb Writing Prefix');
    var pInfo = rootDS.parseInfo;
    if (pInfo.hadPrefix == false && !addMissingPrefix) {
      log.debug2('$wmm not writing prefix');
      return;
    }
    if ((pInfo.preamble != null) && !addCleanPrefix) {
      log.debug2('$wmm writing existing non-zero prefix: ${pInfo.preamble}');
      for (int i = 0; i < 128; i++) bd.setUint8(i, pInfo.preamble[i]);
    } else {
      log.debug2('$wmm writing clean prefix');
      for (int i = 0; i < 128; i++) bd.setUint8(i, 0);
    }
    _wIndex += 128;
    _writeAsciiString('DICM');
    log.debug2('$wee Writing Prefix end');
    log.up;
  }

  void _writeDataset(Dataset ds) {
    assert(ds != null);
    Dataset previousDS = _currentDS;
    _currentDS = ds;
    log.debugDown('$wbb writeDataset: $ds isExplicitVR(${ds.isEVR})');
    for (Element e in ds.elements) _writeElement(e);
    _currentDS = previousDS;
    log.debugUp('$wee end writeDataset');
  }

  void _writeElement(Element e) {
    elementIndex[nthElement] = _wIndex;
    nthElement++;
    log.debugDown('$wbb writing: ${e.info}');
    if (e.isSequence) {
      log.debug1('$wmm Writing Sequence: $e');
      _writeSequence(e);
    } else {
      _writeHeader(e);
      _writeBytes(e.vfBytes);
    }
    if (e.hadUndefinedLength) {
      assert(_undefinedLengthElements.contains(e.vrCode));
      _writeDelimiter(kSequenceDelimitationItem);
    }
    _nElements++;
    if (e.isPrivate) _nPrivateElements++;
    log.debugUp('$wee wrote: $e');
  }

  /// Writes an EVR (short == 8 bytes, long == 12 bytes) or IVR (8 bytes)
  /// header.
  void _writeHeader(Element e) {
    var length = (e.vfLength == null || removeUndefinedLengths)
        ? e.vfBytes.lengthInBytes
        : e.vfLength;
    int start = _wIndex;
    // Write Tag
    _writeTagCode(e.code);
    if (_isEVR) {
      // Write VR
      _writeUint16(e.vrCode);
      if (e.vr.hasShortVF) {
        // Write short EVR VF Length
        _writeUint16(length);
        assert(_wIndex == start + 8);
      } else {
        // Write long EVR VF Length
        _writeUint16(0);
        _writeUint32(length);
        assert(_wIndex == start + 12);
      }
    } else {
      // Write IVR VF Length
      _writeUint32(length);
      assert(_wIndex == start + 8);
    }
  }

  void _writeSequence(Element e) {
    assert(e.isSequence);
    log.debugDown('$wbb SQ $e');
    _writeHeader(e);

    _writeItems(e);
    if (e.hadUndefinedLength) _writeDelimiter(kSequenceDelimitationItem);
    _nSequences++;
    if (e.isPrivate) _nPrivateSequences++;
    log.debugUp('$wee SQ');
  }

  void _writeItems(Element e) {
    var items = e.values;
    for (Dataset item in items) {
      log.debugDown('$wbb Writing Item: $item');
      _writeDelimiter(kItem, item.vfLength);
      for (Element e in item.elements) _writeElement(e);
      if (item.hadULength) _writeDelimiter(kItemDelimitationItem);
      log.debugUp('$wee Wrote Item: $item');
    }
  }
/*  Flush if not needed.
  /// TODO: DOC
  _writeFragments(BytePixelData e, bool isEVR) {
    _writeTagCode(e.code);
    if (isEVR) {
      _writeUint16(e.vrCode);
      _writeUint16(0);
    }
    _writeUint32(kUndefinedLength);
    for (Uint8List f in e.fragments.fragments) {
      _writeTagCode(kItem);
      _writeUint32(f.lengthInBytes);
      _writeBytes(f);
    }
    _writeDelimiter(kSequenceDelimitationItem);
  }*/

  /// Writes the [delimiter] and a zero length field for the [delimiter].
  /// The [_wIndex] is advanced 8 bytes.
  /// Note: There are four [Element]s ([SQ], [OB], [OW], and [UN]) plus
  /// Items that might have an Undefined Length value(0xFFFFFFFF).
  /// if [removeUndefinedLengths] is true this method should not be called.
  void _writeDelimiter(int delimiter, [int lengthInBytes = 0]) {
    assert(removeUndefinedLengths == false);
    //  log.debug('$wmm delimiter(${toHex32(delimiter)})');
    _writeTagCode(delimiter);
    _writeUint32(lengthInBytes);
  }

  void _writeTagCode(int code) {
    _writeUint16(code >> 16);
    _writeUint16(code & 0xFFFF);
  }

/* Flush if not used.
  /// Writes a byte (Uint8) value to the output [bd].
  void _writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    bd.setUint8(_wIndex, value);
    _wIndex++;
  }*/

  /// Writes a 16-bit unsigned integer (Uint16) value to the output [bd].
  void _writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    bd.setUint16(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to the output [bd].
  void _writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    bd.setUint32(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 4;
  }

  /// Writes [bytes] to the output [bd].
  void _writeBytes(Uint8List bytes) {
    int limit = bytes.length;
    for (int i = 0, j = _wIndex; i < limit; i++, j++) bd.setUint8(j, bytes[i]);
    _wIndex = _wIndex + limit;
  }

  /// Writes [bytes], which contains Code Units to the output [bd],
  /// ensuring that an even number of bytes are written, by adding
  /// a padding character if necessary.
  void _writeStringBytes(Uint8List bytes, [int padChar = kSpace]) {
    _writeBytes(bytes);
    if (bytes.length.isOdd) {
      bd.setUint8(_wIndex, padChar);
      _wIndex++;
    }
  }

  /// Writes an [ASCII] [String] to the output [bd].
  void _writeAsciiString(String s,
          [int offset = 0, int limit, int padChar = kSpace]) =>
      _writeStringBytes(ASCII.encode(s), padChar);

/* Flush if not used.
  /// Writes an [UTF8] [String] to the output [bd].
  void _writeUtf8String(String s, [int offset = 0, int limit]) =>
      _writeStringBytes(UTF8.encode(s), kSpace);
*/
/*  Flush if not used.
  void _endOfBDError(int end) {
    throw 'EndOfBD length($end) _wIndex($_wIndex}) LIBytes(${bd
        .lengthInBytes})';
  }*/

  // The current [_wIndex] as a string.
  String get _www => 'W@$_wIndex';

  /// The beginning of writing an [Element] or [Item].
  String get wbb => '> $_www';

  /// In the middle of writing an [Element] or [Item]
  String get wmm => '| $_www';

  /// The end of writing an [Element] or [Item]
  String get wee => '< $_www';

  static getDefaultLength(Dataset ds) =>
      (ds.vfLength == null) ? DcmWriter.defaultBufferLength : ds.vfLength;

  static checkRootDataset(Dataset ds) {
    if (ds == null || ds.length == 0)
      throw new ArgumentError('Empty ' 'Empty Dataset: $ds');
  }

  static checkFile(File file, bool overwrite) {
    if (file == null) throw new ArgumentError('null File');
    if (file.existsSync() && !overwrite)
      throw new ArgumentError('$file already exists');
  }

  static checkPath(String path) {
    if (path == null || path == "")
      throw new ArgumentError('Empty path: $path');
  }
  static ByteData _reuseBD([int size = defaultBufferLength]) {
    if (_reuse == null) return _reuse = new ByteData(size);
    if (size > _reuse.lengthInBytes) {
      _reuse = new ByteData(size + 1024);
      log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
          .lengthInBytes}');
    }
    return _reuse;
  }
}
