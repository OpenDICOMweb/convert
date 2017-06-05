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
import 'package:core/core.dart';

const List<int> _undefinedLengthElements = const <int>[
  kOBCode,
  kOWCode,
  kUNCode
];

//bool _undefinedAllowed(int vrCode) =>
// _undefinedLengthElements.contains(vrCode);

//TODO: remove log.debug when working

//TODO: rewrite all comments to reflect current state of code

/// A [class] for writing a [Dataset] to a [Uint8List], and then
/// possibly writing it to a [File].
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
class DcmByteWriter {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.info);

  //TODO: make the buffer grow and shrink adaptively.
  //TODO: doc
  //Urgent: this should grow and shrink automatically
  static const int defaultBufferLength = 200 * kMB;
  static ByteData _reuse;

  /// The root Dataset being written.
  final RootByteDataset rootDS;

  /// The source of the [Uint8List] being read.
  final String path;

  /// The [TransferSyntax] for the output.
  final TransferSyntax outputTS;

  /// The [Endianness] of the output.
  final Endianness endianness;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// if [true] [Dataset]s will be allowed to be written in IVRLE.
  final bool allowImplicitLittleEndian;

  /// If [true], a DICOM File Prefix (PS3.10) will be written even
  /// if it wasn't present when read.
  final bool addMissingPrefix;

  /// If [true], a DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when read.
  final bool addMissingFMI;

  /// if [true], any [Element]s with [kUndefinedLength] are converted
  /// to have actual Value Field lengths.
  final bool removeUndefinedLengths;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  ByteDataset _currentDS;

  // **** Reader fields ****

  final ByteData bd;
  int _wIndex;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmByteWriter]  where [_wIndex] = [writeIndex] = 0.
  DcmByteWriter(this.rootDS,
      {this.path = "",
      this.outputTS,
      this.endianness = Endianness.LITTLE_ENDIAN,
      this.throwOnError = true,
      this.allowImplicitLittleEndian = true,
      this.addMissingPrefix = false,
      this.addMissingFMI = false,
      this.removeUndefinedLengths = false})
      : _wIndex = 0,
        bd = new ByteData(defaultBufferLength);

  DcmByteWriter.fast(this.rootDS,
      {this.path = "",
      this.outputTS,
      this.endianness = Endianness.LITTLE_ENDIAN,
      this.throwOnError = true,
      this.allowImplicitLittleEndian = true,
      this.addMissingPrefix = false,
      this.addMissingFMI = false,
      this.removeUndefinedLengths = false})
      : _wIndex = 0,
        bd = _reuseBD(rootDS.lengthInBytes + 1024) {
    log.debug(
        'Fast Writer creating BD buffer of size: ${_reuse.lengthInBytes}');
  }

  Uint8List get bytes => bd.buffer.asUint8List(0, _wIndex);

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  //TODO: add to logger.
  /// The current readIndex as a string.
  String get www => 'W@$_wIndex';

  /// The beginning of reading an [Element] or [Item].
  String get wbb => '> $www';

  /// In the middle of reading an [Element] or [Item]
  String get wmm => '| $www';

  /// The end of reading an [Element] or [Item]
  String get wee => '< $www';

  /// Writes File Meta Information ([Fmi]) to the output.
  //TODO: if no FMI is present in the rootDS, it should create it is
  //TODO: [addMissingFmi] is true.
  void writeFMI({bool hasPrefix = true}) {
    if (_currentDS != rootDS) log.error('Not rootDS');
    log.debugDown('$wbb writeFmi($_currentDS)');
    if (hasPrefix) _writePrefix();
    log.debug2('$wmm writeMFI: Prefix($hasPrefix) $_currentDS');
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
    log.debugUp('$wee writeFmi end');
  }

  /// Writes the [rootDS] [Dataset] to a Uint8List and returns the [Uint8List].
  Uint8List writeDataset({bool allowMissingFMI = false}) {
    log.debug('$wbb writeDataset: $rootDS');
    _currentDS = rootDS;

    log.debug('TransferSyntax(${_ts.name}), isEncapsulated($_isEncapsulated)');
    if (!allowMissingFMI && !rootDS.hasFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return null;
    }
    _writePrefix();
    //   writeFMI();
    _writeDataset(rootDS);
    var v = bd.buffer.asUint8List(0, _wIndex);
    log.debug('$wee writeDataset: ${rootDS.info}');
    log.info('Returning ${rootDS.length} elements in ${_wIndex} bytes');
    return v;
  }

  /// Writes the [Dataset] to a [Uint8List]. Returns the [Uint8List].
  static Uint8List writeBytes(ByteDataset ds,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    if (ds == null || ds.length == 0)
      throw new ArgumentError('Empty ' 'Empty ByteDataset: $ds');
    var writer = (fast) ? new DcmByteWriter.fast(ds) : new DcmByteWriter(ds);
    Uint8List bytes = writer.writeDataset();
    if (bytes == null || bytes.length == 0) throw 'Invalid bytes error: $bytes';
    log.info('wrote ${bytes.length} bytes to "$path"');
    return bytes;
  }

  /// Writes the [Dataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Uint8List writeFile(ByteDataset ds, File file,
      {bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    if (file == null) throw new ArgumentError('');
    Uint8List bytes;
    try {
      bytes = writeBytes(ds,
          path: file.path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
      file.writeAsBytesSync(bytes);
      log.info('wrote ${bytes.length} bytes to "${file.path}"');
    } on IOException catch (e) {
      print('IOException: $e');
      rethrow;
    }
    return bytes;
  }

  //Fix: If the file exists what to do?
  /// Creates a new empty [File] at [path], writes the [Dataset] to a
  /// [Uint8List], and then writes the [Uint8List] to the [File].
  /// Returns the [Uint8List].
  static Uint8List writePath(ByteDataset ds, String path,
      {bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    if (path == "") throw new ArgumentError('Empty path: $path');
    return writeFile(ds, new File(path),
        fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  }

  // Enhancement
  /// Writes the [Dataset] in the [Instance] to a [Uint8List]. If [path]
  /// is not empty, creates a new empty[File] at [path], and writes the
  /// [Dataset] to it. Returns the [Uint8List].
  static Uint8List writeInstance(Instance instance,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    Dataset ds = instance.dataset;
    return (path == "")
        ? writeBytes(ds, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS)
        : writePath(ds, path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  }

  static Uint8List write(Dataset ds,
      {String path = "",
      File file,
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    if (file != null)
      return writeFile(ds, file,
          fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (path != "")
      return writePath(ds, path,
          fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    return writeBytes(ds, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  }

  // **** External Interface for Testing
  // **** These methods should not be used in the code above.

  /// Returns [true] if the File Meta Information was present and
  /// write successfully.
  void xWriteFmi(Dataset rds) {
    if (!rds.hasFmi || !rds.hasValidTransferSyntax) return null;
    writeFMI();
  }

  Uint8List xWriteDataset(Dataset ds) {
    log.debugDown('$wbb writeDataset: isExplicitVR(${ds.isEVR})');
    var writer = new DcmByteWriter(ds);
    writer._writeDataset(ds);
    log.debugUp('$wee end writeDataset: isExplicitVR(${ds.isEVR})');
    return writer.bytes;
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

  // **** Internal methods below this line ****

  TransferSyntax get _ts => rootDS.transferSyntax;

  bool get isEVR => rootDS.isEVR;

  bool get _isEncapsulated => _ts.isEncapsulated;

  int get _endOfBD => bd.lengthInBytes;

  void _endOfBDError(int end) {
    throw 'EndOfBD length($end) _wIndex($_wIndex}) LIBytes(${bd
        .lengthInBytes})';
  }

  bool _hasRemaining(int n) {
    if ((_wIndex + n) >= bd.lengthInBytes) _endOfBDError(_wIndex + n);
    return true;
  }

  /// Writes a byte (Uint8) value to the output [bd].
  void _writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    bd.setUint8(_wIndex, value);
    _wIndex++;
  }

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
    for (int i = 0, j = _wIndex; i < limit; i++, j++) {
      bd.setUint8(j, bytes[i]);
    }
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

  /// Writes an [UTF8] [String] to the output [bd].
  void _writeUtf8String(String s, [int offset = 0, int limit]) =>
      _writeStringBytes(UTF8.encode(s), kSpace);

  // **** DICOM encoding stuff ****

  bool get _isFMIPresent => rootDS.hasFMI;

/*
  /// Returns [true] if the [Dataset] being write has an
  /// Explicit VR Transfer Syntax.
  bool get isExplicitVR => rootDS.isExplicitVR;
*/

  void _writeTagCode(int tag) {
    _writeUint16(tag >> 16);
    _writeUint16(tag & 0xFFFF);
  }

  bool _isFMICode(int code) => code >= 0x00020000 && code < 0x00020016;

  bool _isNotFMICode(int code) => !_isFMICode(code);

  void _writePrefix() {
    log.debug1('Writing Prefix');
    if (rootDS.hadPrefix) {
      log.debug2('DS Prefix: ${rootDS.prefix}');
      for (int i = 0; i < 128; i++) _writeUint8(rootDS.prefix[i]);
      log.debug2('DS Prefix: ${bd.buffer.asUint8List(0, 132)}');
      _writeAsciiString('DICM');
    } else if (addMissingPrefix) {
      for (int i = 0; i < 128; i++) _writeUint8(0);
      _writeAsciiString('DICM');
    } else {
      log.error('Dataset $rootDS is missing DICOM Prefix');
    }
  }

  void _writeDataset(Dataset ds) {
    _currentDS = ds;
    log.down;
    assert(_currentDS != null);
    log.debug('$wbb writeDataset: $ds isEVR(${ds.isEVR})');
    for (Element e in ds.elements) _writeElement(e);
    log.debug('$wee end writeDataset');
    log.up;
  }

  void _writeElement(Element e) {
    _hasRemaining(e.lengthInBytes);
    if (rootDS.isEVR)
      _writeEVR(e);
    else
      _writeIVR(e);
  }

  void _writeEVRVFLength(Element e) {
    if (e.vr.hasShortVF) {
      _writeUint16(e.vfLength);
    } else {
      _writeUint16(0);
      if (e.vfLength == kUndefinedLength)
        _writeUint32(kUndefinedLength);
      else
        _writeUint32(e.vfBytes.lengthInBytes);
    }
  }

  void _writeEVR(Element e) {
    log.down;
    assert(rootDS.isEVR);
    if (e is EVRSequence) {
      log.debug('$wbb writing sequence: $e');
      _writeSequence(e);
      log.debug('$wee writing sequence');
    } else if (e is EVRPixelData) {
      if (_isEncapsulated) _writeFragments(e, true);
    } else {
      int start = _wIndex;
      log.debug1(
          '$wbb _writeEVR ${toDcm(e.code)} end(${start + e.vfBytes.length})');
      _writeTagCode(e.code);
      _writeUint16(e.vrCode);
      _writeEVRVFLength(e);
      _writeBytes(e.vfBytes);
 //*** what to do with this?
 //     assert(e.eLengthInBytes == e.lengthInBytes + e.headerLength,
 //         '$wmm e.LIB(${e.lengthInBytes}) != e.e.LIB(${e.bd.lengthInBytes})');
      if (e.wasUndefined) _writeSequenceDelimiter();
      log.debug1('$wee _writeEVR end');
    }
    log.up;
  }

  /// TODO: DOC
  _writeFragments(EVRPixelData e, bool isEVR) {
    _writeTagCode(e.code);
    if (isEVR) {
      _writeUint16(e.vrCode);
      _writeUint16(0);
    }
    _writeUint32(kUndefinedLength);
    for (Uint8List f in e.fragments) {
      _writeTagCode(kItem);
      _writeUint32(f.lengthInBytes);
      _writeBytes(f);
    }
    _writeDelimiter(kSequenceDelimitationItem);
  }

  void _writeIVR(Element e) {
    if (e is IVRSequence) {
      log.debug('$wbb writing sequence: $e');
      _writeSequence(e);
      log.debug('$wee writing sequence');
    } else if (e is EVRPixelData && _isEncapsulated) {
      _writeFragments(e, true);
    } else {
      _writeTagCode(e.code);
      if (e.vfLength == kUndefinedLength) {
        _writeUint32(kUndefinedLength);
      } else {
        _writeUint32(e.vfBytes.lengthInBytes);
      }
      _writeBytes(e.vfBytes);
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
  void _writeSequence(Element e) {
    //TODO: move the for loop out of if when Sequence is a subtype of Element
    int start = _wIndex;
    log.debug2('$wbb _writeSequence: $e');
    log.debug2('$wbb _writeSequence: _wIndex($_wIndex) '
        'e.lengthInBytes(${e.lengthInBytes}) bd.offset(${e.bd.offsetInBytes})');
    if (rootDS.isEVR) {
      _writeEVRSQHeader(e);
      for (Dataset item in e.items) _writeItem(item);
    } else if (e is IVRSequence) {
      _writeIVRSQHeader(e);
      for (Item item in e.items) _writeItem(item);
    }
    log.debug2('$wmm _writeSequence: e.vfLength(${e.vfLength})');
    if (e.vfLength == kUndefinedLength) _writeSequenceDelimiter();
    int end = _wIndex;

    //    var b = bd.buffer.asUint8List(start, end - start);
    //   log.debug('(${e.bytes.lengthInBytes})${e.bytes}');
    //   log.debug('(${b.lengthInBytes})$b');
    if ((end - start) != e.lengthInBytes) {
      log.debug('Invalid SQ: length(${e.lengthInBytes}) end($end) - start'
          '($start) = ${end - start}');
      throw 'Invalid SQ:';
    }
    log.debug2('$wee _writeSequence: _wIndex($_wIndex) bd.offset(${e.bd
        .offsetInBytes + e.bd.lengthInBytes})');
  }

  void _writeEVRSQHeader(Element e) {
    int start = _wIndex;
    log.debug('$wbb _writeEVRSQHeader');
    _writeTagCode(e.code);
    _writeUint16(kSQCode);
    _writeUint16(0);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vfBytes.lengthInBytes);
      //TODO:  if (e.vf.lengthInBytes.isOdd)
    }
    int end = _wIndex;
    var bdx = bd.buffer.asUint8List(start, end - start);
    log.debug('$wee _writeEVRSQHeader: start($start), end($end), '
        'length(${end - start})\n    writeEVRSQHeader: $bdx');
  }

  void _writeIVRSQHeader(Element e) {
    _writeTagCode(e.code);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vfBytes.lengthInBytes);
      //TODO:  if (e.vf.lengthInBytes.isOdd)
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
      //   int vfLength = _getItemLengthInBytes(item);
      int vfLength = item.vfLength;
      _writeUint32(vfLength);
    }
    for (Element e in item.elements) _writeElement(e);
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

/* Flush if not needed.
  /// writes the Value Field until the [kSequenceDelimiter] is found.
  int _getItemLengthInBytes(Item item) {
    int vfLength = 0;
    for (Element e in item.elements) vfLength += e.lengthInBytes;
    return vfLength;
  }*/

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
