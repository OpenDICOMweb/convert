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

import 'package:core/core.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/core.dart';

import 'byte_data_buffer.dart';

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
  /// The default [ByteData] buffer length, if none is provided.
  static const int defaultBufferLength = 200 * k1MB;

  /// If [reUseBD] is [true] the [ByteData] buffer is stored here.
  static ByteData _reuse;

  /// The target output [path] for the encoded data. [file] has
  /// precedence over [path].
  final String path;

  /// The target output [file] for the encoded data. [file] has
  /// precedence over [path].
  final File file;

  /// The [TransferSyntax] for the encoded output. If [null]
  /// the output will have the same [TransferSyntax] as the Root
  /// [Dataset]. If the [TransferSyntax] of the Root [Dataset] is
  /// [null] then it defaults to [Explicit VR Little Endian].
  final TransferSyntax targetTS;

  /// If [true] errors will throw; otherwise, they return [null].
  /// The default is [true].
  final bool throwOnError;

  // The length of the initial output ByteData buffer.
  final int bufferLength;

  final bool reUseBD;

  final EncodingParameters encoding;

  final ElementList elementList = new ElementList();

  /// The current dataset.  This changes as Sequences are written.
  Dataset _currentDS;

  /// Return [true] if input is Explicit VR, [false] if Implicit VR.
  bool _isEVR;
  TransferSyntax _ts;

  //TODO: these should be reported in an EncodeData structure (like ParseData)
  int _nElements = 0;
  int _nSequences = 0;
  int _nPrivateElements = 0;
  int _nPrivateSequences = 0;

  /// Creates a new [DcmByteWriter], where [_wIndex] = [writeIndex] = 0.
  DcmWriter(Dataset rootDS,
      {this.path,
      this.file,
      TransferSyntax outputTS,
      this.throwOnError = true,
      this.bufferLength,
      this.reUseBD = true,
      this.encoding = EncodingParameters.kNoChange})
      : targetTS = getOutputTS(rootDS, outputTS),
        _wIndex = 0,
        _bd = (reUseBD)
            ? _reuseBuffer(bufferLength)
            : new ByteData(
                (bufferLength == null) ? defaultBufferLength : bufferLength);

  /// Returns the [targetTS] for the encoded output.
  static TransferSyntax getOutputTS(Dataset rootDS, TransferSyntax outputTS) {
    if (outputTS == null) {
      return (rootDS.transferSyntax == null)
          ? system.defaultTransferSyntax
          : rootDS.transferSyntax;
    } else {
      return outputTS;
    }
  }

  /// The [ByteData] buffer being written.
  ByteData get bd => _bd;


  /// Returns a [Uint8List] view of the [ByteData] buffer at the current time
  Uint8List get bytes => _bd.buffer.asUint8List(0, _wIndex);

  /// Return's the current position of the write index ([_wIndex]).
  int get wIndex => _wIndex;

  /// Returns the underlying [ByteBuffer].
  ByteBuffer get buffer => _bd.buffer;

  /// Returns [true] if there is space left in the write buffer.
  bool get isWriteable => _isWritable;

  /// The root Dataset being encoded.
  Dataset get rootDS;

  TransferSyntax get ts => rootDS.transferSyntax;

  /// The current dataset.  This changes as Sequences and Items are encoded.
  Dataset get currentDS => _currentDS;

  /// Sets the [currentDS] to [ds].
  set currentDS(Dataset ds) => _currentDS = ds;

  /// The current [length] in bytes of [this].
  int get lengthInBytes => _wIndex;

  /// The current [length] in bytes of [this].
  int get length => lengthInBytes;

  /// Returns [info] about [this].
  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Writes (encodes) only the FMI in the root [Dataset] in 'application/dicom'
  /// media type, writes it to a Uint8List, and returns the [Uint8List].
  Uint8List dcmWriteFMI(bool hadFmi) {
    _writeFMI(hadFmi);
    var bytes = _bd.buffer.asUint8List(0, _wIndex);
    _writeFileOrPath(bytes);
    return bytes;
  }

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List dcmWriteRootDataset() {
    //TODO: handle doSeparateBulkdata
    _currentDS = rootDS;
    _ts = (targetTS == null) ? rootDS.transferSyntax : targetTS;
    if (_ts == null) throw 'no TS';
    //TODO: figure out the correct way to writeFMI
    // _writeFMI();
    _writePrefix();

    _isEVR = rootDS.isEVR;
    _writeDataset(rootDS);
    var encoding = _bd.buffer.asUint8List(0, _wIndex);
    if (encoding == null || encoding.length < 256)
      throw 'Invalid bytes error: $encoding';
    _writeFileOrPath(encoding);
    return encoding;
  }

  //TODO: make this work for [async] == [true] and make that the default.
  /// Writes [bytes] to [file] if it is not [null]; otherwise, writes to
  /// [path] if it is not null. If both are [null] nothing is written.
  void _writeFileOrPath(Uint8List bytes) {
    var f = (file == null && path != "") ? new File(path) : file;
    if (f != null) {
      f.writeAsBytesSync(bytes);
    }
  }

  /// Writes a [Dataset] to the buffer.
  void writeDataset(Dataset ds) => _writeDataset(ds);

  /// Testing interface
  void xWriteElement(Element e) => _writeElement(e);

  // **** Aids to pretty printing - these may go away.

  /// The current readIndex as a string.
  String get www => 'W@$wIndex';

  /// The beginning of reading an [ByteElement] or [ByteItem].
  String get wbb => '> $www';

  /// In the middle of reading an [ByteElement] or [ByteItem]
  String get wmm => '| $www';

  /// The end of reading an [ByteElement] or [ByteItem]
  String get wee => '< $www';


  // **** Private methods

  /// Writes File Meta Information ([FMI]) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  bool _writeFMI(bool hadFmi) {
    //  if (encoding.doUpdateFMI) return writeODWFMI();
    if (_currentDS != rootDS) log.error('Not rootDS');

    // Check to see if we should write FMI if missing
    if (!hadFmi && encoding.allowMissingFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return false;
    } else if (encoding.doUpdateFMI && (!hadFmi && encoding.doAddMissingFMI)) {
      _writeODWFMI();
    } else {
      assert(hadFmi);
      _writeExistingFMI();
    }
    _isEVR = rootDS.isEVR;
    return true;
  }

  void _writeExistingFMI() {
    _isEVR = true;
    _writePrefix();
    for (Element e in rootDS.elements) {
      if (e.code < 0x00030000) {
        _writeElement(e);
      } else {
        break;
      }
    }
  }

  /// Writes a new Open DICOMweb FMI.
  void _writeODWFMI() {
    //Urgent finish
  }

  //TODO: redoc
  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  void _writePrefix() {
    var pInfo = rootDS.parseInfo;
    assert(pInfo.hadPrefix == false || !encoding.doAddMissingFMI);
    if (pInfo.preambleWasZeros || encoding.doCleanPreamble) {
      for (int i = 0; i < 128; i++) _bd.setUint8(i, 0);
    } else {
      assert(pInfo.preamble != null && !encoding.doCleanPreamble);
      for (int i = 0; i < 128; i++) _bd.setUint8(i, pInfo.preamble[i]);
    }
    _skip(128);
    _writeAsciiString('DICM');
  }

  void _writeDataset(Dataset ds) {
    assert(ds != null);
    Dataset previousDS = _currentDS;
    _currentDS = ds;

    _isEVR = true;
    for (Element e in ds.elements) {
      //Urgent Jim: figure out how to move this outside loop.
      //  should fmi be a separate map in the rootDS?
      if (e.code > 0x30000) _isEVR = rootDS.isEVR;
      _writeElement(e);
    }
    _currentDS = previousDS;
  }

  void _writeElement(Element e) {
    int eStart = _wIndex;
    if (e.isSequence) {
      _writeSequence(e);
    } else {
      if (e.code == kPixelData) {
        _writePixelData(e);
      } else {
        _writeSimpleElement(e);
      }
    }
    elementList.add(eStart, _wIndex, e);
    _nElements++;
    if (e.isPrivate) _nPrivateElements++;
  }

  // Simple, i.e. not a sequence or Pixel Data.
  void _writeSimpleElement(Element e) {
    //TODO: handle replacing undefined lengths
    //TODO: doFixPaddingErrors
    _writeHeader(e);
    _writeBytes(e.vfBytes);
    if (e.hadULength) {
      assert(kUndefinedLengthVRCodes.contains(e.vrCode));
      _writeDelimiter(kSequenceDelimitationItem);
    }
  }

  /// Writes an EVR (short == 8 bytes, long == 12 bytes) or IVR (8 bytes)
  /// header.
  void _writeHeader(Element e) {
    var length = (e.vfLength == null || encoding.doConvertUndefinedLengths)
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
        _writeUint16(e.vfLength);
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
    //TODO: handle replacing undefined lengths
    _writeHeader(e);
    var sq = e as SequenceMixin;
    if (sq.items.length > 0) _writeItems(e);
    if (e.hadULength) _writeDelimiter(kSequenceDelimitationItem);
    _nSequences++;
    if (e.isPrivate) _nPrivateSequences++;
  }

  void _writeItems(Element e) {
    if (!e.isSequence) throw '$e Not Sequence';
    //TODO: handle replacing undefined lengths
    var sq = e as SequenceMixin;
    List<ByteItem> items = sq.items;
    for (Dataset item in items) {
      _writeDelimiter(kItem, item.vfLength);
      for (Element e in item.elements) _writeElement(e);
      if (item.hadULength) _writeDelimiter(kItemDelimitationItem);
    }
  }

  /// Write encapsulated (compressed) [kPixelData] from [Element] [e].
  void _writePixelData(Element e) {
    //TODO: handle replacing undefined lengths
    //TODO: handle doRemoveFragments
    PixelDataMixin pd = e as PixelDataMixin;
    if (pd.fragments != null) {
      _writeHeader(e);
      for (Uint8List fragment in pd.fragments.fragments) {
        _writeTagCode(kItem);
        _writeUint32(fragment.lengthInBytes);
        _writeBytes(fragment);
      }
      _writeDelimiter(kSequenceDelimitationItem);
    } else {
      _writeSimpleElement(e);
    }
  }

  /// Writes the [delimiter] and a zero length field for the [delimiter].
  /// The [_wIndex] is advanced 8 bytes.
  /// Note: There are four [Element]s ([SQ], [OB], [OW], and [UN]) plus
  /// Items that might have an Undefined Length value(0xFFFFFFFF).
  /// if [removeUndefinedLengths] is true this method should not be called.
  void _writeDelimiter(int delimiter, [int lengthInBytes = 0]) {
    //TODO: handle doRemoveNoZeroDelimiterLengths
    assert(encoding.doConvertUndefinedLengths == false);
    _writeTagCode(delimiter);
    _writeUint32(lengthInBytes);
  }

  void _writeTagCode(int code) {
    _writeUint16(code >> 16);
    _writeUint16(code & 0xFFFF);
  }

  // **** Buffer management

  /// The [ByteDataBuffer] buffer being written.
  ByteData _bd;

  int _wIndex = 0;
  // int get endOfBD => _bd.lengthInBytes;

  /// Returns [true] if there is space left in the write buffer.
  bool get _isWritable => _wIndex < _bd.lengthInBytes;

  /// Moves the [_wIndex] forward [n] bytes, or backward if [n] is negative.
  void _skip(int n) {
    int v = _wIndex + n;
    // Note: keep next line for debugging
    // _checkRange(v);
    _wIndex = v;
  }

/* Keep for debugging
  void _checkRange(int v) {
    int max = _bd.lengthInBytes;
    if (v < 0 || v >= max) throw new RangeError.range(v, 0, max);
  }
*/

  // The Writers

/* Flush if not needed
  /// Writes a byte (Uint8) value to the output [_bd].
  void _writeUint8(int value) {
    assert(value >= 0 && value <= 255, 'Value out of range: $value');
    _maybeGrow(1);
    _bd.setUint8(_wIndex, value);
    _wIndex++;
  }*/

  /// Writes a 16-bit unsigned integer (Uint16) value to the output [_bd].
  void _writeUint16(int value) {
    assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
    _maybeGrow(2);
    _bd.setUint16(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 2;
  }

  /// Writes a 32-bit unsigned integer (Uint32) value to the output [_bd].
  void _writeUint32(int value) {
    assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
    _maybeGrow(4);
    _bd.setUint32(_wIndex, value, Endianness.HOST_ENDIAN);
    _wIndex += 4;
  }

  /// Writes [bytes] to the output [_bd].
  void _writeBytes(Uint8List bytes) => __writeBytes(bytes);

  void __writeBytes(Uint8List bytes) {
    int length = bytes.lengthInBytes;
    _maybeGrow(length);
    for (int i = 0, j = _wIndex; i < length; i++, j++)
      _bd.setUint8(j, bytes[i]);
    _wIndex = _wIndex + length;
  }

  /// Writes [bytes], which contains Code Units to the output [_bd],
  /// ensuring that an even number of bytes are written, by adding
  /// a padding character if necessary.
  void _writeStringBytes(Uint8List bytes, [int padChar = kSpace]) {
    //TODO: doFixPaddingErrors
    _writeBytes(bytes);
    if (bytes.length.isOdd) {
      _bd.setUint8(_wIndex, padChar);
      _wIndex++;
    }
  }

  //TODO: doFixPaddingErrors
  /// Writes an [ASCII] [String] to the output [_bd].
  void _writeAsciiString(String s,
          [int offset = 0, int limit, int padChar = kSpace]) =>
      _writeStringBytes(ASCII.encode(s), padChar);

  /// Writes an [UTF8] [String] to the output [_bd].
  void writeUtf8String(String s, [int offset = 0, int limit]) =>
      _writeStringBytes(UTF8.encode(s), kSpace);

  /// Ensures that [_bd] is at least [index] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  void ensureRemaining(int index, int remaining) =>
      ensureCapacity(index + remaining);

  /// Ensures that [_bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) =>
      (capacity > _bd.lengthInBytes) ? _grow() : null;

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  void _maybeGrow([int size = 1]) {
    if (_wIndex + size >= _bd.lengthInBytes) _grow();
  }

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [capacity] is null the new buffer will be twice the size of the
  /// current buffer. If [capacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  void _grow([int capacity]) {
    int oldLength = _bd.lengthInBytes;
    int newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;

    _isValidBufferLength(newLength);
    if (newLength < oldLength) return;
    var newBuffer = new ByteData(newLength);
    for (int i = 0; i < oldLength; i++) newBuffer.setUint8(i, _bd.getUint8(i));
    _bd = newBuffer;
  }

  static ByteData _reuseBuffer([int size = defaultBufferLength]) {
    if (size == null) size = defaultBufferLength;
    if (_reuse == null) return _reuse = new ByteData(size);
    if (size > _reuse.lengthInBytes) {
      _reuse = new ByteData(size + 1024);
      log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
          .lengthInBytes}');
    }
    return _reuse;
  }
}

const int defaultLength = 16;
const int k1GB = 1024 * 1024 * 1024;

int _isValidBufferLength(int length, [int maxLength = k1GB]) {
  RangeError.checkValidRange(1, length, maxLength);
  return length;
}
