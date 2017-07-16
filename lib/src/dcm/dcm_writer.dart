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

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'byte_data_writer.dart';

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
  static final Logger log = new Logger("DcmWriter", watermark: Severity.info);

  //Urgent: this should grow and shrink automatically
  static const int defaultBufferLength = 200 * kMB;
  static ByteDataBuffer _reuse;

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

  /// The [ByteDataBuffer] buffer being written.
  final ByteDataBuffer buf;

  final List<int> elementIndex = new List<int>(2000);
  int nthElement = 0;

  /// The current dataset.  This changes as Sequences are written.
  Dataset _currentDS;

  bool _isEVR;
  TransferSyntax _ts;
  bool _isEncapsulated;
//  int _wIndex = 0;

  int _nElements = 0;
  int _nSequences = 0;
  int _nPrivateElements = 0;
  int _nPrivateSequences = 0;

  //*** Constructors ***

  //TODO: Doc
  /// Creates a new [DcmByteWriter]  where [_wIndex] = [writeIndex] = 0.
  DcmWriter(
    int length, {
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
      : buf = (reUseBD) ? _reuseBD(length) :
  new ByteDataBuffer((length == null) ? defaultBufferLength : length);

  // **** Interface:
  /// The root Dataset being encoded.
  Dataset get rootDS;

  /// The current dataset.  This changes as Sequences are encoded.
  Dataset get currentDS => _currentDS;
  void set currentDS(Dataset ds) => _currentDS = ds;

  /// The current [length] in bytes of [this].
  int get length => buf.wIndex;

  /// Returns [info] about [this].
  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Write only the FMI, and returns only the bytes that were written.
  Uint8List writeFMI() {
    _writeFMI();
    return buf.buffer.asUint8List(0, buf.wIndex);
  }

  /// Writes the [rootDS] [Dataset] to a Uint8List and returns the [Uint8List].
  Uint8List writeRootDataset() {
    log.debug('${buf.wbb} writeRootDataset: $rootDS');
    _currentDS = rootDS;
    _ts = rootDS.transferSyntax;
    _isEncapsulated = rootDS.transferSyntax.isEncapsulated;
    _isEVR = rootDS.isEVR;
    log.debug('${buf.wmm} TS(${_ts.name}), isEncapsulated($_isEncapsulated)');
    if (!allowMissingFMI && !rootDS.hasFMI) {
      log.error('Dataset $rootDS is missing FMI elements');
      return null;
    }

    if (rootDS.parseInfo.hadPrefix || addMissingPrefix) _writePrefix();
    // Writes the FMI as normal elements
    // TODO: this does not add missing FMI elements
    _writeDataset(rootDS);
    log.debug('${buf.wmm} _nElements: $_nElements');
    log.debug('${buf.wmm} _nSequences: $_nSequences');
    log.debug('${buf.wmm} _nPrivateElements: $_nPrivateElements');
    log.debug('${buf.wmm} _nPrivateSequences: $_nPrivateSequences');
    log.debug('${buf.wmm} writeRootDataset: ${rootDS.info}');
    log.debug('${buf.wee} Returning ${rootDS.length} elements in ${buf.wIndex} bytes');
    var bytes = buf.buffer.asUint8List(0, buf.wIndex);
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
    log.debugDown('${buf.wbb} writeFmi($_currentDS)');
    if (rootDS.parseInfo.hadPrefix || addMissingPrefix) _writePrefix();
    for (Element e in rootDS.elements) {
      while (e.code < 0x00030000) {
        _writeElement(e);
        log.debug2('${buf.wmm} writeFMI loop: $e');
      }
      break;
    }
    log.debugUp('${buf.wee} writeFmi end');
  }

  //TODO: redoc
  /// If the Root [Dataset] was parsed and had a prefix,
  /// then it was all zeros or not.
  void _writePrefix() {
    log.down;
    log.debug2('${buf.wbb} Writing Prefix');
    var pInfo = rootDS.parseInfo;
    if (pInfo.hadPrefix == false && !addMissingPrefix) {
      log.debug2('${buf.wmm} not writing prefix');
      log.up;
      return;
    }
    if ((pInfo.preamble != null) && !addCleanPrefix) {
      log.debug2('${buf.wmm} writing existing non-zero prefix: ${pInfo.preamble}');
      for (int i = 0; i < 128; i++) buf.bd.setUint8(i, pInfo.preamble[i]);
    } else {
      log.debug2('${buf.wmm} writing clean prefix');
      for (int i = 0; i < 128; i++) buf.bd.setUint8(i, 0);
    }
    buf.skip(128);
    buf.writeAsciiString('DICM');
    log.debug2('${buf.wee} Writing Prefix end');
    log.up;
  }

  void _writeDataset(Dataset ds) {
    assert(ds != null);
    Dataset previousDS = _currentDS;
    _currentDS = ds;
    log.debugDown('${buf.wbb} writeDataset: $ds isExplicitVR(${ds.isEVR})');
    for (Element e in ds.elements) _writeElement(e);
    _currentDS = previousDS;
    log.debugUp('${buf.wee} end writeDataset');
  }

  void _writeElement(Element e) {
    elementIndex[nthElement] = buf.wIndex;
    nthElement++;
    log.debugDown('${buf.wbb} writing: ${e.info}');
    if (e.isSequence) {
      _writeSequence(e);
    } else {
      _writeHeader(e);
      buf.writeBytes(e.vfBytes);
    }
    if (e.hadUndefinedLength) {
      assert(kUndefinedLengthElements.contains(e.vrCode));
      _writeDelimiter(kSequenceDelimitationItem);
    }
    _nElements++;
    if (e.isPrivate) _nPrivateElements++;
    log.debugUp('${buf.wee} wrote: $e');
  }

  /// Writes an EVR (short == 8 bytes, long == 12 bytes) or IVR (8 bytes)
  /// header.
  void _writeHeader(Element e) {
    var length = (e.vfLength == null || removeUndefinedLengths)
        ? e.vfBytes.lengthInBytes
        : e.vfLength;
    int start = buf.wIndex;
    // Write Tag
    _writeTagCode(e.code);
    if (_isEVR) {
      // Write VR
      buf.writeUint16(e.vrCode);
      if (e.vr.hasShortVF) {
        // Write short EVR VF Length
        buf.writeUint16(length);
        assert(buf.wIndex == start + 8);
      } else {
        // Write long EVR VF Length
        buf.writeUint16(0);
        buf.writeUint32(length);
        assert(buf.wIndex == start + 12);
      }
    } else {
      // Write IVR VF Length
      buf.writeUint32(length);
      assert(buf.wIndex == start + 8);
    }
  }

  void _writeSequence(Element e) {
    assert(e.isSequence);
    log.debugDown('${buf.wbb} SQ $e');
    _writeHeader(e);
    _writeItems(e);
    if (e.hadUndefinedLength) _writeDelimiter(kSequenceDelimitationItem);
    _nSequences++;
    if (e.isPrivate) _nPrivateSequences++;
    log.debugUp('${buf.wee} SQ');
  }

  void _writeItems(Element e) {
    var items = e.values;
    for (Dataset item in items) {
      log.debugDown('${buf.wbb} Writing Item: $item');
      _writeDelimiter(kItem, item.vfLength);
      for (Element e in item.elements) _writeElement(e);
      if (item.hadULength) _writeDelimiter(kItemDelimitationItem);
      log.debugUp('${buf.wee} Wrote Item: $item');
    }
  }
/*  Flush if not needed.
  /// TODO: DOC
  _writeFragments(BytePixelData e, bool isEVR) {
    _writeTagCode(e.code);
    if (isEVR) {
      buf.writeUint16(e.vrCode);
      buf.writeUint16(0);
    }
    buf.writeUint32(kUndefinedLength);
    for (Uint8List f in e.fragments.fragments) {
      _writeTagCode(kItem);
      buf.writeUint32(f.lengthInBytes);
      buf.writeBytes(f);
    }
    _writeDelimiter(kSequenceDelimitationItem);
  }*/

  /// Writes the [delimiter] and a zero length field for the [delimiter].
  /// The [buf.wIndex] is advanced 8 bytes.
  /// Note: There are four [Element]s ([SQ], [OB], [OW], and [UN]) plus
  /// Items that might have an Undefined Length value(0xFFFFFFFF).
  /// if [removeUndefinedLengths] is true this method should not be called.
  void _writeDelimiter(int delimiter, [int lengthInBytes = 0]) {
    assert(removeUndefinedLengths == false);
    _writeTagCode(delimiter);
    buf.writeUint32(lengthInBytes);
  }

  void _writeTagCode(int code) {
    buf.writeUint16(code >> 16);
    buf.writeUint16(code & 0xFFFF);
  }

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

  static ByteDataBuffer _reuseBD([int size = defaultBufferLength]) {
    if (_reuse == null) return _reuse = new ByteDataBuffer(size);
    if (size > _reuse.lengthInBytes) {
      _reuse = new ByteDataBuffer(size + 1024);
      log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
          .lengthInBytes}');
    }
    return _reuse;
  }
}
