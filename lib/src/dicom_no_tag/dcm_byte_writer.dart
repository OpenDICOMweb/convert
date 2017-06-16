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
class DcmByteWriter {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.debug2);

  //TODO: make the buffer grow and shrink adaptively.
  //TODO: doc
  //Urgent: this should grow and shrink automatically
  static const int defaultBufferLength = 200 * kMB;
  static ByteData _reuse;

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

  final bool removeUndefinedLengths;

  final bool reUseBD;

  /// The root Dataset for the object being read.
  final RootByteDataset rootDS;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  Dataset _currentDS;

  TransferSyntax _transferSyntax;
  bool _isEncapsulated;

  // **** Reader fields ****

  final ByteData bd;
  int _wIndex;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmByteWriter]  where [_wIndex] = [writeIndex] = 0.
  DcmByteWriter(
    this.rootDS, {
    this.path = "",
    this.outputTS,
    this.endianness = Endianness.LITTLE_ENDIAN,
    this.throwOnError = true,
    this.allowImplicitLittleEndian = true,
    this.addMissingPrefix = false,
    this.addMissingFMI = false,
    this.removeUndefinedLengths = false,
    this.reUseBD = true,
  })
      : _wIndex = 0,
        bd = (reUseBD)
            ? _reuseBD(rootDS.vfLength + 1024)
            : new ByteData(rootDS.vfLength);

  Uint8List get bytes => bd.buffer.asUint8List(0, _wIndex);

  void _endOfBDError(int end) {
    throw 'EndOfBD length($end) _wIndex($_wIndex}) LIBytes(${bd
        .lengthInBytes})';
  }

  bool _hasRemaining(int n) {
    if ((_wIndex + n) >= bd.lengthInBytes) _endOfBDError(_wIndex + n);
    return true;
  }

  /// The current readIndex as a string.
  String get www => 'W@$_wIndex';

  /// The beginning of reading an [ByteElement] or [ByteItem].
  String get wbb => '> $www';

  /// In the middle of reading an [ByteElement] or [ByteItem]
  String get wmm => '| $www';

  /// The end of reading an [ByteElement] or [ByteItem]
  String get wee => '< $www';

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

  void _writeTagCode(int tag) {
    _writeUint16(tag >> 16);
    _writeUint16(tag & 0xFFFF);
  }

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Writes File Meta Information ([Fmi]) to the output.
  //TODO: if no FMI is present in the rootDS, should it create it?
  //TODO: [addMissingFmi] is true.
  void writeFMI({bool hasPrefix = true}) {
    if (_currentDS != rootDS) log.error('Not rootDS');
    log.debugDown('$wbb writeFmi($_currentDS)');
    if (hasPrefix) _writePrefix();
    log.debug2('$wmm writePrefix: Prefix($hasPrefix) $_currentDS');
    for (ByteElement e in rootDS.elements) {
      while (e.code < 0x00030000) {
        _writeElement(e);
        log.debug1('$wmm writeFMI loop: $e');
      }
    }
    log.debugUp('$wee writeFmi end');
  }

  /// writes a [RootByteDataset] from [this] and returns it. If an error is
  /// encountered [writeRootDataset] will throw an Error is or [null].
  Uint8List writeRootDataset({bool allowMissingFMI = false}) {
    log.debug('$wbb writeRootDataset: $rootDS');
    _currentDS = rootDS;
    _transferSyntax = rootDS.transferSyntax;
    _isEncapsulated = rootDS.transferSyntax.isEncapsulated;

    log.debug('$wmm TransferSyntax(${_transferSyntax.name}), isEncapsulated'
        '($_isEncapsulated)');

    if (!allowMissingFMI && !rootDS.hasFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return null;
    }
    _writePrefix();
    _writeDataset(rootDS);
    var v = bd.buffer.asUint8List(0, _wIndex);
    log.debug2('$wmm writeRootDataset: ${rootDS.info}');
    log.debug('$wee Returning ${rootDS.length} elements in ${_wIndex} bytes');
    return v;
  }

  void _writePrefix() {
    log.down;
    log.debug2('$wbb Writing Prefix');
    if (rootDS.part10 != null) {
      log.debug2('$wmm writing existing Part10: all zeros: '
          '${rootDS.part10.wasPreambleZeros}');
      ByteData bd = rootDS.part10.bd;
      for (int i = 0; i < 128; i++) _writeUint8(bd.getUint8(i));
      _writeAsciiString('DICM');
      log.debug2('$wmm writing new Prefix');
    } else if (addMissingPrefix) {
      for (int i = 0; i < 128; i++) _writeUint8(0);
      _writeAsciiString('DICM');
    } else {
      log.error('Dataset $rootDS is missing DICOM Prefix');
    }
    log.debug2('$wee Writing Prefix end');
    log.up;
  }

  void _writeDataset(Dataset ds) {
    _currentDS = ds;
    log.down;
    assert(_currentDS != null);
    log.debug('$wbb writeDataset: $ds isExplicitVR(${ds.isEVR})');
    for (ByteElement e in ds.elements) _writeElement(e);
    log.debug('$wee end writeDataset');
    log.up;
  }

  void _writeElement(ByteElement e) {
    _hasRemaining(e.lengthInBytes);
    if (e.isEVR)
      _writeEVR(e);
    else
      _writeIVR(e);
  }

  void _writeEVRVFLength(ByteElement e) {
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

  void _writeEVR(ByteElement e) {
    log.down;
    assert(e.isEVR);
    if (e is EVRSequence) {
      log.debug('$wbb writing sequence: $e');
      _writeSequence(e);
      log.debug('$wee writing sequence');
    } else if (e is EVRPixelData && _isEncapsulated) {
      log.debug('$wbb writing Encapsulated Pixel Data: $e');
      _writeFragments(e, true);
      log.debug('$wee writing Encapsulated Pixel Data');
    } else {
      log.debug('$wbb _writeEVR $e'
          'end(${_wIndex + e.vfBytes.length})');
      _writeTagCode(e.code);
      _writeUint16(e.vrCode);
      _writeEVRVFLength(e);
      _writeBytes(e.vfBytes);
      log.debug('$wmm e.LIB(${e.lengthInBytes}) != '
          'e.e.LIB(${e.bd.lengthInBytes})');
      assert(e.lengthInBytes != bd.lengthInBytes,
          '$wmm e.LIB(${e.lengthInBytes}) != e.e.LIB(${e.bd.lengthInBytes})');
      if (e.hadUndefinedLength) _writeSequenceDelimiter();
      log.debug1('$wee _writeEVR end');
    }
    log.up;
  }

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
  }

  void _writeIVR(ByteElement e) {
    log.down;
    assert(e.isEVR);
    if (e is IVRSequence) {
      log.debug('$wbb writing sequence: $e');
      _writeSequence(e);
      log.debug('$wee writing sequence');
    } else if (e is IVRPixelData && _isEncapsulated) {
      log.debug('$wbb writing Encapsulated Pixel Data: $e');
      _writeFragments(e, true);
      log.debug('$wee writing Encapsulated Pixel Data');
    } else {
      _writeTagCode(e.code);
      if (e.vfLength == kUndefinedLength) {
        _writeUint32(kUndefinedLength);
      } else {
        _writeUint32(e.vfBytes.lengthInBytes);
      }
      _writeBytes(e.vfBytes);
      if (e.hadUndefinedLength) _writeSequenceDelimiter();
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
    log.debug('$wbb _writeSequence: _wIndex($_wIndex) '
        'e.lengthInBytes(${e.lengthInBytes}) '
        'bd.offset(${e.bd.offsetInBytes})');
    log.debug('e.lengthInBytes(${e.lengthInBytes}), '
        'e.vfLength(${e.vfBytes.lengthInBytes}), e.vfOffset(${e.vfOffset})');
    assert(e.lengthInBytes == e.vfBytes.lengthInBytes + e.vfOffset);
    // Enhancement: remove if when Type descrimination isn't needed.
    if (e is EVRSequence) {
      _writeEVRSQHeader(e);
      for (ByteItem item in e.items) _writeItem(item);
    } else if (e is IVRSequence) {
      _writeIVRSQHeader(e);
      for (ByteItem item in e.items) _writeItem(item);
    }
    log.debug2('$wmm _writeSequence: e.vfLength(${e.vfLength})');
    if (e.vfLength == kUndefinedLength) _writeSequenceDelimiter();
    int end = _wIndex;
    if ((end - start) != e.lengthInBytes) {
      log.error('$wmm Invalid SQ: length(${e.lengthInBytes}) end($end) - start'
          '($start) = ${end - start}');
      throw 'Invalid SQ:';
    }
    log.debug('$wee _writeSequence: _wIndex($_wIndex) bd.offset(${e.bd
        .offsetInBytes + e.bd.lengthInBytes})');
  }

  void _writeEVRSQHeader(ByteElement e) {
    int start = _wIndex;
    log.debugDown('$wbb _writeEVRSQHeader');
    _writeTagCode(e.code);
    _writeUint16(kSQCode);
    _writeUint16(0);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vfBytes.lengthInBytes);
      //TODO:  if (e.vf.lengthInBytes.isOdd)
    }
    // var bdx = bd.buffer.asUint8List(start, end - start);
    log.debugUp('$wee _writeEVRSQH: start($start), end($_wIndex), '
        'length(${_wIndex - start})');
  }

  void _writeIVRSQHeader(ByteElement e) {
    int start = _wIndex;
    log.debugDown('$wbb _writeIVRSQHeader');
    _writeTagCode(e.code);
    if (e.vfLength == kUndefinedLength) {
      _writeUint32(kUndefinedLength);
    } else {
      _writeUint32(e.vfBytes.lengthInBytes);
      //TODO:  if (e.vf.lengthInBytes.isOdd)
    }
    log.debugUp('$wee _writeIVRSQH: start($start), end($_wIndex), '
        'length(${_wIndex - start}) ');
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & writeElementExplicit
  /// Returns an [ByteItem] or Fragment.
  void _writeItem(ByteItem item) {
    log.debugDown('$wbb writeItemElements: ${item.length} Items');
    _writeTagCode(kItem);
    if (item.hadULength) {
      _writeUint32(kUndefinedLength);
    } else {
      int vfLength = item.vfLength;
      _writeUint32(vfLength);
    }
    for (ByteElement e in item.elements) _writeElement(e);
    if (item.hadULength) _writeItemDelimiter();
    log.debugUp('$wee writeItemElements: ${item.length} Items');
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

  //Urgent Move to TestByteWriter
// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// write successfully.
  void xWriteFmi(RootByteDataset rds) {
    if (!rds.hasFMI || !rds.hasSupportedTransferSyntax) return null;
    writeFMI();
  }

  Uint8List xWriteDataset(ByteDataset ds) {
    log.debugDown('$wbb writeDataset: isExplicitVR(${ds.isEVR})');
    var writer = new DcmByteWriter(ds);
    writer._writeDataset(ds);
    log.debugUp('$wee end writeDataset: isExplicitVR(${ds.isEVR})');
    return writer.bytes;
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

  static ByteData _reuseBD([int size = defaultBufferLength]) {
    if (_reuse == null) return _reuse = new ByteData(size);
    if (size > _reuse.lengthInBytes) {
      _reuse = new ByteData(size + 1024);
      log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
          .lengthInBytes}');
    }
    return _reuse;
  }

  static Uint8List writeBytes(ByteDataset ds,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    if (ds == null || ds.length == 0)
      throw new ArgumentError('Empty ' 'Empty ByteDataset: $ds');
    var writer = new DcmByteWriter(ds);
    Uint8List bytes = writer.writeRootDataset();
    //log.debug('bytes: $bytes');
    if (bytes == null || bytes.length == 0) throw 'Invalid bytes error: $bytes';
    log.debug('Wrote ${bytes.length} bytes to "$path"');
    return bytes;
  }

  static Uint8List writeFile(ByteDataset ds, File file,
      {bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    if (file == null) throw new ArgumentError('');
    Uint8List bytes;
    try {
      bytes = writeBytes(ds,
          path: file.path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
      file.writeAsBytesSync(bytes);
      log.debug('Wrote ${bytes.length} bytes to "${file.path}"');
    } on IOException catch (e) {
      log.error('IOException: $e');
      rethrow;
    }
    return bytes;
  }

  static Uint8List writePath(ByteDataset ds, String path,
      {bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    if (path == "") throw new ArgumentError('Empty path: $path');
    return writeFile(ds, new File(path),
        fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  }

/* Enhancement
  static Uint8List writeInstance(Instance instance,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    ByteDataset ds = instance.dataset;
    return (path == "")
        ? writeBytes(ds, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS)
        : writePath(ds, path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  }
*/

  static Uint8List write(ByteDataset ds,
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
}
