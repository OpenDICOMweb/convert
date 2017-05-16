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
class DcmWriter {
  ///TODO: doc
  static final Logger log = new Logger("DcmReader", watermark: Severity.config);

  /// The source of the [Uint8List] being read.
  final String path;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  final bool allowImplicitLittleEndian;
  final bool allowMissingFMI;
  //   final TransferSyntax targetTS;

  /// The root Dataset for the object being read.
  final RootByteDataset rootDS;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  ByteDataset _currentDS;

  // **** Reader fields ****

  final ByteData _bd;
  int _wIndex = 0;

  //Urgent: this should grow and shrink automatically
  static const int defaultBDSize = 30 * kMB;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmWriter]  where [_wIndex] = [writeIndex] = 0.
  DcmWriter(
    this.rootDS, {
    this.path = "",
    this.throwOnError = true,
    this.allowImplicitLittleEndian = true,
    this.allowMissingFMI = false,
  })
      : _bd = new ByteData(30 * kMB);

  DcmWriter.fast(
    this.rootDS, {
    this.path = "",
    this.throwOnError = true,
    this.allowImplicitLittleEndian = true,
    this.allowMissingFMI = false,
  })
      : _bd = _reuseBD();

  Uint8List get bytes => _bd.buffer.asUint8List(0, _wIndex);

  int get endOfBD => _bd.lengthInBytes;

  void endOfBDError(int length) {
    throw 'EndOfBD length($length) _wIndex($_wIndex}) LIBytes(${_bd
        .lengthInBytes})';
  }

  bool hasRemaining(int n) {
    if ((_wIndex + n) >= _bd.lengthInBytes) endOfBDError(n);
    return true;
  }

  /* bool get _isWritable {
    if (_wIndex >= _bd.lengthInBytes) endOfBDError(1);
    return true;
  } */

  /// The current readIndex as a string.
  String get www => 'W@$_wIndex';

  /// The beginning of reading an [ByteElement] or [ByteItem].
  String get wbb => '> $www';

  /// In the middle of reading an [ByteElement] or [ByteItem]
  String get wmm => '| $www';

  /// The end of reading an [ByteElement] or [ByteItem]
  String get wee => '< $www';

  void _writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _bd.setUint8(_wIndex, value);
    _wIndex++;
  }

  void _writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _bd.setUint16(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 2;
  }

  void _writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _bd.setUint32(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 4;
  }

  void _writeBytes(Uint8List bytes) {
    int limit = bytes.length;
    for (int i = 0, j = _wIndex; i < limit; i++, j++) {
      _bd.setUint8(j, bytes[i]);
    }
    _wIndex = _wIndex + limit;
  }

  void _writeStringBytes(Uint8List bytes, [int padChar = kSpace]) {
    /*
    int limit = bytes.length;
    for (int i = 0; i < limit; i++) {
      _bd.setUint8(_wIndex, bytes[i]);
      _wIndex++;
    }
    */
    _writeBytes(bytes);
//    _wIndex += bytes.length;
    if (bytes.length.isOdd) {
      _bd.setUint8(_wIndex, padChar);
      _wIndex++;
    }
  }

  void _writeAsciiString(String s,
          [int offset = 0, int limit, int padChar = kSpace]) =>
      _writeStringBytes(ASCII.encode(s), padChar);

  void _writeUtf8String(String s, [int offset = 0, int limit]) =>
      _writeStringBytes(UTF8.encode(s), kSpace);

  // **** DICOM encoding stuff ****

  bool get isFMIPresent => rootDS.hasFMI;

  /// Returns [true] if the [ByteDataset] being write has an
  /// Explicit VR Transfer Syntax.
  bool get isExplicitVR => rootDS.isExplicitVR;

  void _writeTagCode(int tag) {
    _writeUint16(tag >> 16);
    _writeUint16(tag & 0xFFFF);
  }

  bool isFMICode(int code) => code >= 0x00020000 && code < 0x00020016;

  bool isNotFMICode(int code) => !isFMICode(code);
  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// writes File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [ByteElement]s were present; otherwise, returns null.
  void writeFMI({bool hasPrefix = true}) {
    if (_currentDS != rootDS) log.error('Not rootDS');
    log.down;
    log.debug('$wbb writeFmi($_currentDS)');
    if (hasPrefix) _writePrefix();
    log.debug2('$wmm writeMFI: prefix($hasPrefix) $_currentDS');
    log.down;
    log.debug1('$wbb writeFMI loop:');
    for (ByteElement e in rootDS.elements) {
      if (e.isFMI) {
        _writeElement(e);
        log.debug1('$wmm writeFMI loop: $e');
      } else {
        break;
      }
    }
    log.debug('$wee writeFmi end');
    log.up;
  }

  /// writes a [RootByteDataset] from [this] and returns it. If an error is
  /// encountered [writeRootDataset] will throw an Error is or [null].
  RootByteDataset writeRootDataset({bool allowMissingFMI = false}) {
    log.debug('$wbb writeRootDataset: $rootDS');
    _currentDS = rootDS;
    if (!allowMissingFMI && !rootDS.hasFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return null;
    }
    _writePrefix();
    //   writeFMI();
    _writeDataset(rootDS);
    log.debug('$wee writeRootDataset: ${rootDS.info}');
    return rootDS;
  }

  void _writePrefix() {
    hasRemaining(132);
    for (int i = 0; i < 128; i++) _writeUint8(0);
    _writeAsciiString('DICM');
  }

  void _writeDataset(ByteDataset ds) {
    _currentDS = ds;
    log.down;
    assert(_currentDS != null);
    log.debug('$wbb writeDataset: $ds isExplicitVR(${ds.isExplicitVR})');
    for (ByteElement e in ds.elements) _writeElement(e);
    log.debug('$wee end writeDataset');
    log.up;
  }

  void _writeElement(ByteElement e) {
    hasRemaining(e.lengthInBytes);
    if (e.isExplicitVR)
      _writeEVR(e);
    else
      _writeIVR(e);
  }

  void _writeEVRVFLength(EVRElement e) {
    if (e.vr.hasShortVF) {
      _writeUint16(e.vfLength);
    } else {
      _writeUint16(0);
      if (e.vfLength == kUndefinedLength)
        _writeUint32(kUndefinedLength);
      else
        _writeUint32(e.vf.lengthInBytes);
    }
  }

  void _writeEVR(ByteElement e) {
    log.down;
    if (e is EVRSequence) {
      log.debug('$wbb writing sequence: $e');
      _writeSequence(e);
      log.debug('$wee writing sequence');
    } else {
      int start = _wIndex;
      log.debug1(
          '$wbb _writeEVR ${toDcm(e.code)} end(${start + e.bytes.length}');
      _writeTagCode(e.code);
      _writeUint16(e.vrCode);
      _writeEVRVFLength(e);
      _writeBytes(e.vf);
      assert(e.lengthInBytes == e.bd.lengthInBytes,
          '$wmm e.LIB(${e.lengthInBytes}) != e.e.LIB(${e.bd.lengthInBytes})');
  //    var bdx = _bd.buffer.asByteData(start, e.lengthInBytes);
  //    var e1 = new EVRElement(bdx);
      if (e.wasUndefined) _writeSequenceDelimiter();
      log.debug1('$wee _writeEVR end');
    }
    log.up;
  }

  void _writeIVR(ByteElement e) {
    if (e is IVRSequence) {
      log.debug('$wbb writing sequence: $e');
      _writeSequence(e);
      log.debug('$wee writing sequence');
    } else {
      _writeTagCode(e.code);
      if (e.vfLength == kUndefinedLength) {
        _writeUint32(kUndefinedLength);
      } else {
        _writeUint32(e.vf.lengthInBytes);
      }
      _writeBytes(e.vf);
      if (e.wasUndefined) _writeSequenceDelimiter();
      log.debug1('$wee _writeIVR: $e');
      log.up;
    }
  }

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // writeing the value field of these [Element]s. Returns an [SQ] [Element].

  /// writes an EVR or IVR Sequence. The _writeElementMethod detects Sequences.
  void _writeSequence(ByteElement e) {
    //TODO: move the for loop out of if when Sequence is a subtype of Element
    int start = _wIndex;
    if (e is EVRSequence) {
      _writeEVRSQHeader(e);
      for (ByteItem item in e.items) _writeItem(item);
    } else if (e is IVRSequence) {
      _writeIVRSQHeader(e);
      for (ByteItem item in e.items) _writeItem(item);
    }
    if (e.vfLength == kUndefinedLength) _writeSequenceDelimiter();
    int end = _wIndex;

    //    var b = bd.buffer.asUint8List(start, end - start);
    //   log.debug('(${e.bytes.lengthInBytes})${e.bytes}');
    //   log.debug('(${b.lengthInBytes})$b');
    if ((end - start) != e.lengthInBytes) {
      throw 'Invalid SQ:';
    }
  }

  void _writeEVRSQHeader(ByteElement e) {
    int start = _wIndex;
    log.debug('$wbb writeEVRSQHeader');
    _writeTagCode(e.code);
    _writeUint16(kSQCode);
    _writeUint16(0);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vf.length);
      //TODO:  if (e.vf.length.isOdd)
    }
    int end = _wIndex;
    var bdx = _bd.buffer.asUint8List(start, end - start);
    log.debug('$wee writeEVRSQHeader: start($start), end($end), '
        'length(${end - start}\n    writeEVRSQHeader: $bdx');
  }

  void _writeIVRSQHeader(ByteElement e) {
    _writeTagCode(e.code);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vf.length);
      //TODO:  if (e.vf.length.isOdd)
    }
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & writeElementExplicit
  /// Returns an [ByteItem] or Fragment.
  void _writeItem(ByteItem item) {
    log.down;
    _writeTagCode(kItem);
    if (item.hadUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      int vfLength = _getItemLengthInBytes(item);
      _writeUint32(vfLength);
    }
    for (ByteElement e in item.elements) _writeElement(e);
    if (item.hadUndefinedLength) _writeItemDelimiter();
    log.debug('$wee writeItemElements: ${item.length} Items');
    log.up;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  void _writeSequenceDelimiter() {
    //  log.debug('$wmm check SQ Delimiter');
    _writeDelimiter(kSequenceDelimitationItem);
  }

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  void _writeItemDelimiter() {
    //  log.debug('$wmm check Item Delimiter');
    _writeDelimiter(kItemDelimitationItem);
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_wIndex] is advanced past the Value Length Field;
  /// otherwise, writeIndex does not change
  void _writeDelimiter(int delimiter) {
    //  log.debug('$wmm delimiter(${toHex32(delimiter)})');
    _writeTagCode(delimiter);
    _writeUint32(0);
  }

  /// writes the Value Field until the [kSequenceDelimiter] is found.
  int _getItemLengthInBytes(ByteItem item) {
    int vfLength = 0;
    for (ByteElement e in item.elements) vfLength += e.lengthInBytes;
    return vfLength;
  }

// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// write successfully.
  void xWriteFmi(RootByteDataset rds) {
    if (!rds.hasFMI || !rds.hasValidTransferSyntax) return null;
    writeFMI();
  }

  void xWritePublicElement(ByteElement e) => _writeElement(e);

  // External Interface for testing
  void xWritePGLength(ByteElement e) => _writeElement(e);

  // External Interface for testing
  void xWritePrivateIllegal(int code, ByteElement e) => _writeElement(e);

  // External Interface for testing
  void xWritePrivateCreator(ByteElement e) => _writeElement(e);

  // External Interface for testing
  void xWritePrivateData(ByteElement pc, ByteElement e) => _writeElement(e);

  // writes
  Uint8List xWriteDataset(ByteDataset ds) {
    log.debugDown('$wbb writeDataset: isExplicitVR(${ds.isExplicitVR})');
    var writer = new DcmWriter(ds);
    writer._writeDataset(ds);
    log.debugUp('$wee end writeDataset: isExplicitVR(${ds.isExplicitVR})');
    return writer.bytes;
  }

  static ByteData _reuse;
  static ByteData _reuseBD([int size = defaultBDSize]) {
    if (_reuse == null) _reuse = new ByteData(defaultBDSize);
    return _reuse;
  }

  static void _writeFile(Uint8List bytes, String path) {
    if (path != null || path != "") {
      var file = new File(path);
      file.writeAsBytesSync(bytes);
      log.info('wrote ${bytes.length} bytes to "$path"');
    }
  }

  static Uint8List fmi(RootByteDataset rds, {String path = "", bool fast = false}) {
    var writer = new DcmWriter(rds, path: path);
    writer.writeFMI();
    var bytes = writer.bytes;
    //TODO: should this be writing?
    if (path != "") _writeFile(bytes, path);
    return bytes;
  }

  static Uint8List rootDataset(RootByteDataset rds,
      {String path = "", bool fast = false}) {
    var writer = (fast)
        ? new DcmWriter.fast(rds, path: path)
        : new DcmWriter(rds, path: path);
    writer.writeRootDataset();
    var bytes = writer.bytes;
    //TODO: should this be writing?
    if (path != "") _writeFile(bytes, path);
    return bytes;
  }

  static Uint8List dataset(ByteDataset ds, {String path = "", bool fast = false}) {
    var writer = (fast) ? new DcmWriter.fast(ds) : new DcmWriter(ds);
    writer.xWriteDataset(ds);
    var bytes = writer.bytes;
    //TODO: should this be writing?
    if (path != "") _writeFile(bytes, path);
    return bytes;
  }
}


