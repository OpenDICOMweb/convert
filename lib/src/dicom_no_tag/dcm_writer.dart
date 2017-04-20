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
class DcmWriter {
  ///TODO: doc
  static final Logger log = new Logger("DcmReader", watermark: Severity.debug2);

  /// The source of the [Uint8List] being read.
  final String path;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  final bool allowImplicitLittleEndian;
  final bool allowMissingFMI;
  //   final TransferSyntax targetTS;

  /// The root Dataset for the object being read.
  final RootDataset rootDS;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  Dataset _currentDS;

  // **** Reader fields ****

  final ByteData bd;
  int _wIndex = 0;

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
      : bd = new ByteData(2 * kMB);

  Uint8List get bytes => bd.buffer.asUint8List(0, _wIndex);

  int get endOfBD => bd.lengthInBytes;

  void endOfBDError(int length) {
    throw 'EndOfBD length($length) _wIndex($_wIndex}) LIBytes(${bd
        .lengthInBytes})';
  }

  bool hasRemaining(int n) {
    if ((_wIndex + n) >= bd.lengthInBytes) endOfBDError(n);
    return true;
  }

  bool get _isWritable {
    if (_wIndex >= bd.lengthInBytes) endOfBDError(1);
    return true;
  }

  /// The current readIndex as a string.
  String get www => 'W@$_wIndex';

  /// The beginning of reading an [Element] or [Item].
  String get wbb => '> $www';

  /// In the middle of reading an [Element] or [Item]
  String get wmm => '| $www';

  /// The end of reading an [Element] or [Item]
  String get wee => '< $www';

  void _writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    bd.setUint8(_wIndex, value);
    _wIndex++;
  }

  void _writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    bd.setUint16(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 2;
  }

  void _writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    bd.setUint32(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 4;
  }

  int _skip(int n) {
    int index = _wIndex + n;
    if (index >= 0 && index < endOfBD) {
      _wIndex = index;
      return _wIndex;
    }
    throw '_skip Index($n) out of range';
  }

  void _writeBytes(Uint8List bytes, [int offset = 0, int limit]) {
    if (limit == null) limit = bytes.length;
    for (int i = 0; i < limit; i++) {
      bd.setUint8(_wIndex, bytes[i]);
      _wIndex++;
    }
 //   _wIndex = end;
  }

  void _writeStringBytes(Uint8List bytes,
      [int offset = 0, int limit, int padChar = kSpace]) {
    if (limit == null) limit = bytes.length;
    for (int i = offset; i < limit; i++) {
      bd.setUint8(_wIndex, bytes[i]);
      _wIndex++;
    }
//    _wIndex += bytes.length;
      if (bytes.length.isOdd) {
        bd.setUint8(_wIndex, padChar);
        _wIndex++;
      }
    }

  void _writeAsciiString(String s,
          [int offset = 0, int limit, int padChar = kSpace]) =>
      _writeStringBytes(ASCII.encode(s), offset, limit, padChar);

  void _writeUtf8String(String s, [int offset = 0, int limit]) =>
      _writeStringBytes(UTF8.encode(s), offset, limit, kSpace);

  // **** DICOM encoding stuff ****

  bool get isFMIPresent => rootDS.isFMIPresent;

  /// Returns [true] if the [Dataset] being write has an
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
  /// if any [Fmi] [Element]s were present; otherwise, returns null.
  void writeFMI({bool hasPrefix = true}) {
    if (_currentDS != rootDS) log.error('Not rootDS');
    log.down;
    log.debug('$wbb writeFmi($_currentDS)');
    if (hasPrefix) _writePrefix();
    log.debug2('$wmm writeMFI: prefix($hasPrefix) $_currentDS');
    log.down;
    log.debug1('$wbb writeFMI loop:');
    for (Element e in rootDS.elements) {
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

  /// writes a [RootDataset] from [this] and returns it. If an error is
  /// encountered [writeRootDataset] will throw an Error is or [null].
  RootDataset writeRootDataset({bool allowMissingFMI = false}) {
    log.debug('$wbb writeRootDataset: ${rootDS.info}');
    _currentDS = rootDS;
    if (!allowMissingFMI && !rootDS.isFMIPresent) {
      log.error('Dataset $rootDS is missing FMI elements');
      return null;
    }

    writeFMI();
    _writeDataset(rootDS);
    log.debug('$wee writeRootDataset: ${rootDS.info}');
    return rootDS;
  }

  void _writePrefix() {
    hasRemaining(132);
    for (int i = 0; i < 128; i++) _writeUint8(0);
    _writeAsciiString('DICM');
  }

  void _writeDataset(Dataset ds) {
    _currentDS = ds;
    log.down;
    assert(_currentDS != null);
    log.debug('$wbb writeDataset: $ds isExplicitVR(${ds.isExplicitVR})');
    for (Element e in ds.elements) {
      if (e.isExplicitVR) {
        _writeEVR(e);
      } else {
        _writeIVR(e);
      }
    }
    log.debug('$wee end writeDataset');
    log.up;
  }

  void _writeElement(Element e) {
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

  void _writeEVR(Element e) {
    if (e is EVRSequence) return _writeSequence(e);
    int start = _wIndex;
    _writeTagCode(e.code);
    _writeUint16(e.vrCode);
    _writeEVRVFLength(e);
    _writeBytes(e.vf);

    if (e.lengthInBytes != e.bd.lengthInBytes)
      log.error('e.LIB(${e.lengthInBytes}) != e.e.LIB(${e.bd.lengthInBytes})');
    var bdx = bd.buffer.asByteData(start, e.lengthInBytes);
    var e1 = new EVRElement(bdx);
    if (e != e1)
      log.error('e: $e != e1: $e1');
    log.debug('  e: $e');
    log.debug('bdx: $bdx');
    if (e.wasUndefined) _writeSequenceDelimiter();
    log.debug1('$wee _writeEVR end');
    log.up;
  }

  void _writeIVR(IVRElement e) {
    if (e is EVRSequence) return _writeSequence(e);
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

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // writeing the value field of these [Element]s. Returns an [SQ] [Element].

  /// writes an EVR or IVR Sequence. The _writeElementMethod detects Sequences.
  void _writeSequence(Element e) {
    //TODO: move the for loop out of if when Sequence is a subtype of Element
    if (e is EVRSequence) {
      _writeEVRSQHeader(e);
      for (Item item in e.items) _writeItem(item);
    } else if (e is IVRSequence) {
      _writeIVRSQHeader(e);
      for (Item item in e.items) _writeItem(item);
    }
    if (e.vfLength == kUndefinedLength) _writeSequenceDelimiter();
  }

  void _writeEVRSQHeader(Element e) {
    _writeUint32(e.code);
    _writeUint16(kSQCode);
    _writeUint16(0);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vf.length);
      //TODO:  if (e.vf.length.isOdd)
    }
  }

  void _writeIVRSQHeader(Element e) {
    _writeUint32(e.code);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vf.length);
      //TODO:  if (e.vf.length.isOdd)
    }
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & writeElementExplicit
  /// Returns an [Item] or Fragment.
  void _writeItem(Item item) {
    log.down;
    _writeTagCode(kItem);
    if (item.hadUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      int vfLength = _getItemLengthInBytes(item);
      _writeUint32(vfLength);
    }
    for (Element e in item.elements) _writeElement(e);
    if (item.hadUndefinedLength) _writeItemDelimiter();
    log.debug('$wee writeItemElements: ${item.length} Items');
    log.up;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  void _writeSequenceDelimiter() {
    log.debug('$wmm check SQ Delimiter');
    _writeDelimiter(kSequenceDelimitationItem);
  }

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  void _writeItemDelimiter() {
    log.debug('$wmm check Item Delimiter');
    _writeDelimiter(kItemDelimitationItem);
  }

  /// Returns [true] if the [target] delimiter is found. If the target
  /// delimiter is found [_wIndex] is advanced past the Value Length Field;
  /// otherwise, writeIndex does not change
  void _writeDelimiter(int delimiter) {
    log.debug('$wmm delimiter(${toHex32(delimiter)})');
    _writeTagCode(delimiter);
    _writeUint32(0);
  }

  /// writes the Value Field until the [kSequenceDelimiter] is found.
  int _getItemLengthInBytes(Item item) {
    int vfLength = 8; // Item header
    for (Element e in item.elements) vfLength += e.lengthInBytes;
    return vfLength;
  }

// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// write successfully.
  void xWriteFmi(RootDataset rds) {
    if (!rds.isFMIPresent || !rds.hasValidTransferSyntax) return null;
    writeFMI();
  }

  void xWritePublicElement(Element e) => _writeElement(e);

  // External Interface for testing
  void xWritePGLength(Element e) => _writeElement(e);

  // External Interface for testing
  void xWritePrivateIllegal(int code, Element e) => _writeElement(e);

  // External Interface for testing
  void xWritePrivateCreator(Element e) => _writeElement(e);

  // External Interface for testing
  void xWritePrivateData(Element pc, Element e) => _writeElement(e);

  // writes
  Uint8List xWriteDataset(Dataset ds) {
    log.down;
    log.debug('$wbb writeDataset: isExplicitVR(${ds.isExplicitVR})');
    var writer = new DcmWriter(ds);
    writer._writeDataset(ds);
    log.debug('$wee end writeDataset: isExplicitVR(${ds.isExplicitVR})');
    log.up;
    return writer.bytes;
  }

  static void _writeFile(Uint8List bytes, String path) {
    if (path != null || path != "") {
      var file = new File(path);
      file.writeAsBytesSync(bytes);
      log.info('wrote ${bytes.length} bytes to "$path"');
    }
  }

  static Uint8List fmi(RootDataset rds, {String path = ""}) {
    var writer = new DcmWriter(rds, path: path);
    writer.writeFMI();
    var bytes = writer.bytes;
    _writeFile(bytes, path);
    return bytes;
  }

  static Uint8List rootDataset(RootDataset rds,
      {String path = "", bool fmiOnly = false}) {
    var writer = new DcmWriter(rds, path: path);
    writer.writeRootDataset();
    var bytes = writer.bytes;
    _writeFile(bytes, path);
    return bytes;
  }

  static Uint8List dataset(Dataset ds, {String path = ""}) {
    var writer = new DcmWriter(ds);
    writer.xWriteDataset(ds);
    var bytes = writer.bytes;
    _writeFile(bytes, path);
    return bytes;
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
