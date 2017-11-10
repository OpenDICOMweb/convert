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

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/byte_list_writer.dart';

import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

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

  /// The default [ByteData] buffer length, if none is provided.
  static const int defaultBufferLength = 200 * k1MB;

  /// If [reUseBD] is true the [ByteData] buffer is stored here.
  static ByteData _reuse;

  /// The target output [path] for the encoded data. [file] has
  /// precedence over [path].
  final String path;

  /// The target output [file] for the encoded data. [file] has
  /// precedence over [path].
  final File file;

  /// The [TransferSyntax] for the encoded output. If null
  /// the output will have the same [TransferSyntax] as the Root
  /// [Dataset]. If the [TransferSyntax] of the Root [Dataset] is
  /// null then it defaults to [Explicit VR Little Endian].
  final TransferSyntax targetTS;

  // The length of the initial output ByteData buffer.
  final int bufferLength;

  final bool reUseBD;

  final EncodingParameters eParams;

  final ElementOffsets elementList = new ElementOffsets();

  /// The current dataset.  This changes as Sequences are written.
  Dataset _currentDS;

  /// Return true if input is Explicit VR, false if Implicit VR.
  bool _isEVR;
  TransferSyntax _ts;

  int _nElements = 0;
  int _nSequences = 0;
  int _nPrivateElements = 0;
  int _nPrivateSequences = 0;

  /// Creates a new [DcmWriter], where [_wIndex] = [wIndex] = 0.
  DcmWriter(Dataset rootDS,
      {this.path,
      this.file,
      TransferSyntax outputTS,
      this.bufferLength,
      this.reUseBD = true,
      this.eParams = EncodingParameters.kNoChange})
      : targetTS = getOutputTS(rootDS, outputTS),
        _wIndex = 0,
        _bd = (reUseBD)
            ? _reuseBuffer(bufferLength)
            : new ByteData(
                (bufferLength == null) ? defaultBufferLength : bufferLength);

  /// Returns the [targetTS] for the encoded output.
  static TransferSyntax getOutputTS(RootDataset rootDS, TransferSyntax outputTS) {
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

  /// Returns true if there is space left in the write buffer.
  bool get isWriteable => _isWritable;

  /// The root Dataset being encoded.
  RootDataset get rootDS;

  TransferSyntax get ts => rootDS.transferSyntax;

/*
  /// The current dataset.  This changes as Sequences and Items are encoded.
  Dataset get currentDS => _currentDS;

  /// Sets the [currentDS] to [ds].
  set currentDS(Dataset ds) => _currentDS = ds;
*/

  /// The current [length] in bytes of this [DcmWriter].
  int get lengthInBytes => _wIndex;

  /// The current [length] in bytes of this [DcmWriter].
  int get length => lengthInBytes;

  /// Returns [info] about this [DcmWriter].
  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Writes (encodes) only the FMI in the root [Dataset] in 'application/dicom'
  /// media type, writes it to a Uint8List, and returns the [Uint8List].
  Uint8List dcmWriteFMI({bool hadFmi}) {
    _writeFMI( hadFmi);
    final bytes = _bd.buffer.asUint8List(0, _wIndex);
    _writeFileOrPath(bytes);
    return bytes;
  }

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List dcmWriteRootDataset() {
    //TODO: handle doSeparateBulkdata
    log.debug('$wbb dcmWriteRootDataset: ${rootDS.info}');
    _currentDS = rootDS;
    _ts = (targetTS == null) ? rootDS.transferSyntax : targetTS;
    if (_ts == null) throw 'no TS';

    log.debug('$wmm TS(${_ts.name}), isEncapsulated(${_ts.isEncapsulated})');
    //TODO: figure out the correct way to writeFMI
    // _writeFMI();
    _writePrefix();

    _isEVR = rootDS.isEVR;
    _writeDataset(rootDS);
    log..debug('$wmm _nElements: $_nElements')
    ..debug('$wmm _nSequences: $_nSequences')
    ..debug('$wmm _nPrivateElements: $_nPrivateElements')
    ..debug('$wmm _nPrivateSequences: $_nPrivateSequences')
    ..debug('$wmm writeRootDataset: ${rootDS.info}')
    ..debug('$wee Returning ${rootDS.length} elements in $_wIndex bytes');
    final bytes = _bd.buffer.asUint8List(0, _wIndex);
    if (bytes == null || bytes.length < 256)
      throw 'Invalid bytes error: $bytes';
    _writeFileOrPath(bytes.path);
    return bytes;
  }



  /// Writes a [Dataset] to the buffer.
  void writeDataset(Dataset ds) => _writeDataset(ds);

  /// Testing interface
  void xWriteElement(Element e) => _writeElement(e);

  // **** Aids to pretty printing - these may go away.

  /// The current readIndex as a string.
  String get www => 'W@$wIndex';

  /// The beginning of reading an [Element] or [Item].
  String get wbb => '> $www';

  /// In the middle of reading an [Element] or [Item]
  String get wmm => '| $www';

  /// The end of reading an [Element] or [Item]
  String get wee => '< $www';


  // **** Private methods

  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  bool _writeFMI(bool hasFmi) {
    //  if (encoding.doUpdateFMI) return writeODWFMI();
    if (_currentDS != rootDS) log.error('Not rootDS');
    log.debug('$wbb writeFMI($_currentDS)', 1);

    // Check to see if we should write FMI if missing
    if (!hasFmi && eParams.allowMissingFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return false;
    } else if (eParams.doUpdateFMI && (!hasFmi && eParams.doAddMissingFMI)) {
      log.debug('$wmm writing new ODW FMI');
      _writeODWFMI();
    } else {
      assert(hasFmi);
      log.debug('$wmm writing existing FMI');
      _writeExistingFMI();
    }
    _isEVR = rootDS.isEVR;
    log.debug('$wee writeFMI @end', -1);
    return true;
  }

  void _writeExistingFMI() {
    log.debug('$wbb write existing FMI($_currentDS)', 1);
    _isEVR = true;
    _writePrefix();
    for (var e in rootDS.elements) {
      log.debug2('$wmm writeFMI: $e');
      if (e.code < 0x00030000) {
        _writeElement(e);
        log.debug2('$wmm writeFMI loop: $e');
      } else {
        break;
      }
    }
    log.debug('$wee write existing FMI @end', -1);
  }

  /// Writes a new Open DICOMweb FMI.
  void _writeODWFMI() {
    //Urgent finish
  }

  //TODO: redoc
  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  void _writePrefix() {
    log.debug2('$wbb Writing Prefix', 1);
    final pInfo = rootDS.parseInfo;
    log.debug('hadPrefix(${pInfo.hadPrefix}), doAddMissingFMI(${eParams
        .doAddMissingFMI})');
    assert(pInfo.hadPrefix == false || !eParams.doAddMissingFMI);
    if (pInfo.preambleWasZeros || eParams.doCleanPreamble) {
      log.debug2('$wmm writing clean Preamble');
      for (var i = 0; i < 128; i++) _bd.setUint8(i, 0);
    } else {
      assert(pInfo.preamble != null && !eParams.doCleanPreamble);

      log.debug2('$wmm writing existing non-zero Preamble: ${pInfo.preamble}');
      for (var i = 0; i < 128; i++) _bd.setUint8(i, pInfo.preamble[i]);
    }
    _skip(128);
    _writeAsciiString('DICM');
    log.debug2('$wee Writing Prefix end', -1);
  }

  void _writeDataset(RootDataset ds) {
    assert(ds != null);
    final previousDS = _currentDS;
    _currentDS = ds;
    log.debug('$wbb writeDataset: $ds isExplicitVR(${ds.isEVR})', 1);

    _isEVR = true;
    for (var e in ds.elements) {
      final eStart = _wIndex;
      log.debug('$wbb write e: $e', 1);
      //TODO: figure out how to move this outside loop.
      //  should fmi be a separate map in the rootDS?
      if (e.code > 0x30000) _isEVR = rootDS.isEVR;
      _writeElement(e);
      final eEnd = _wIndex;
      log.debug('$wee e: $e: Length: ${eEnd - eStart}', -1);
    }
    _currentDS = previousDS;
    log.debug('$wee end writeDataset', -1);
  }

  void _writeElement(Element e) {
    final eStart = _wIndex;
    log.debug('$wbb writing: $e', 1);
    if (e is SQ) {
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
    log.debug('$wee wrote: $e', -1);
  }

  // Simple, i.e. not a sequence or Pixel Data.
  void _writeSimpleElement(Element e) {
    //TODO: handle replacing undefined lengths
    //TODO: doFixPaddingErrors
    log.debug('$wbb $e');
    _writeHeader(e);
    _writeBytes(e.vfBytes);
    if (e.hadULength) {
      log.debug('$wmm Write SQ ULength delimiter');
      assert(kUndefinedLengthVRCodes.contains(e.vrCode));
      _writeDelimiter(kSequenceDelimitationItem);
    }
    log.debug('$wee $e');
  }

  /// Writes an EVR (short == 8 bytes, long == 12 bytes) or IVR (8 bytes)
  /// header.
  void _writeHeader(Element e) {
    log.debug('$wbb writeHeader ${_isEVR ? "EVR" : "IVR"} '
        'e.vfLength: ${e.vfLength}, ${hex32(e.vfLength)}', 1);
    final length = (e.vfLength == null || eParams.doConvertUndefinedLengths)
        ? e.vfBytes.lengthInBytes
        : e.vfLength;
    log.debug('$wmm length: $length');
    final start = _wIndex;
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
    log.debug('$wee writeHeader', -1);
  }



  /// Writes the [delimiter] and a zero length field for the [delimiter].
  /// The [_wIndex] is advanced 8 bytes.
  /// Note: There are four [Element]s ([SQ], [OB], [OW], and [UN]) plus
  /// Items that might have an Undefined Length value(0xFFFFFFFF).
  /// if [eParams].removeUndefinedLengths is true this method should not be called.
  void _writeDelimiter(int delimiter, [int lengthInBytes = 0]) {
    //TODO: handle doRemoveNoZeroDelimiterLengths
    assert(eParams.doConvertUndefinedLengths == false);
    _writeTagCode(delimiter);
    _writeUint32(lengthInBytes);
  }

  void _writeTagCode(int code) {
    _writeUint16(code >> 16);
    _writeUint16(code & 0xFFFF);
  }

  // **** Buffer management

  /// The [ByteListWriter] buffer being written.
  ByteData _bd;

  int _wIndex = 0;
  // int get endOfBD => _bd.lengthInBytes;

  /// Returns true if there is space left in the write buffer.
  bool get _isWritable => _wIndex < _bd.lengthInBytes;

  /// Moves the [_wIndex] forward [n] bytes, or backward if [n] is negative.
  void _skip(int n) {
    final v = _wIndex + n;
    // Note: keep next line for debugging
    // _checkRange(v);
    _wIndex = v;
  }

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
    final length = bytes.lengthInBytes;
    _maybeGrow(length);
    for (var i = 0, j = _wIndex; i < length; i++, j++)
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
    log.debug('start _grow: ${_bd.lengthInBytes}', 1);
    final oldLength = _bd.lengthInBytes;
    var newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;

    _isValidBufferLength(newLength);
    if (newLength < oldLength) return;
    final newBuffer = new ByteData(newLength);
    for (var i = 0; i < oldLength; i++) newBuffer.setUint8(i, _bd.getUint8(i));
    _bd = newBuffer;
    log.debug('end _grow ${_bd.lengthInBytes}', -1);
  }

  static ByteData _reuseBuffer([int size]) {
    size ??= defaultBufferLength;
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
  log.debug('isValidlength: $length');
  RangeError.checkValidRange(1, length, maxLength);
  return length;
}