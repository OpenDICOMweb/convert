//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:typed_data';

import 'package:bytes_dicom/bytes_dicom.dart';
import 'package:constants/constants.dart';
import 'package:core/core.dart';

import 'package:converter/src/binary/base/constants.dart';
import 'package:converter/src/binary/base/padding_chars.dart';
import 'package:converter/src/element_offsets.dart';
import 'package:converter/src/encoding_parameters.dart';

// ignore_for_file: public_member_api_docs

//Urgent Jim: add to EvrULength at appropriate places

typedef ElementSubWriter = void Function(Element e);

/// Default allocation is 16K bytes
const int kMinWriteBufferLength = 0x4000;

abstract class SubWriter {
  /// The current [Dataset].
  Dataset cds;

  /// [Encoding Parameters]
  final EncodingParameters eParams;

  /// The [TransferSyntax] to be written.
  final TransferSyntax outputTS;

  /// The [DicomWriteBuffer] currently being written.
  final DicomWriteBuffer _wb;

  /// Creates a new binary [SubWriter]
  SubWriter(this.cds, this.eParams, this.outputTS, int length)
      : _wb = getWriteBuffer(length);

  /// Creates a new binary [SubWriter]
  SubWriter.from(SubWriter subWriter)
      : _wb = subWriter._wb,
        eParams = subWriter.eParams,
        cds = subWriter.cds,
        outputTS = subWriter.outputTS;

  DicomWriteBuffer get wb => _wb;

  bool get doLogging;

  /// Returns a [Bytes] view of the current [DicomWriteBuffer].
  // Bytes get output => _wb.view();

  /// The number of [Element]s written so far.
  int get count => _count;
  int _count = 0;

  // **** Interface
  /// Returns _true_ if _this_ is an Explicit VR [SubWriter].
  bool get isEvr;

  /// The [RootDataset] being written.
  RootDataset get rds;

  void _writeElement(Element e, [int vrIndex]);

  // void _writeShort(Element e, int vrIndex) => unsupportedError();

  void __writeLongDefinedLengthHeader(
      Element e, int vrIndex, int vfLengthField);

  void __writeLongUndefinedLengthHeader(Element e, int vrIndex);

  // **** End of Interface

  /// Return's the current position in _this_.
  int get wIndex => _wb.wIndex;

  /// The [TransferSyntax] of output.
  TransferSyntax get ts => rds.transferSyntax;

  /// The current [length] in bytes of this [SubWriter].
  int get lengthInBytes => _wb.wIndex;

  /// The current [length] in bytes of this [SubWriter].
  int get length => lengthInBytes;

  ElementOffsets get inputOffsets => null;

  ElementOffsets get offsets => null;

  /// If _true_ no [Dataset]s or [Element]s will have [kUndefinedLength].
  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  /// Returns _true_ if the File Meta Information has been
  /// written to the output.
  bool get isFmiWritten => _isFmiWritten;

  // ignore: prefer_final_fields
  bool _isFmiWritten = false;

  set isFmiWritten(bool v) => _isFmiWritten ??= true;

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  DSBytes writeRootDataset([int fmiEnd, TransferSyntax ts]) {
    final dsStart = _wb.wIndex;
    _wb.bytes.endian = (ts.isBigEndian) ? Endian.big : Endian.little;
    if (doLogging) {
      _startRootDatasetMsg(dsStart, rds, ts);
    }
    _writeDataset(rds);
    final rdsLength = _wb.wIndex;
    final rdsBytes = _wb.view(0, rdsLength);
    final dsBytes = RDSBytes(rdsBytes, fmiEnd);
    rds.dsBytes = dsBytes;
    if (doLogging) _endRootDatasetMsg(dsStart, rds, dsBytes);
    return dsBytes;
  }

  /// Writes a [Dataset] to the output.
  void _writeDataset(Dataset ds) {
    // ignore: prefer_forEach
    for (final e in ds.elements) _writeElement(e);
  }

  /// Write all [Item]s in [items].
  void _writeItems(List<Item> items) {
    for (final item in items) {
      final parentDS = cds;
      cds = item;
      _writeItem(item);
      cds = parentDS;
    }
  }

  /// Write one [Item].
  void _writeItem(Item item) {
    (!eParams.doConvertUndefinedLengths && item.hasULength)
        ? _writeUndefinedLengthItem(item)
        : _writeDefinedLengthItem(item);
  }

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthItem(Item item) {
    final start = _wb.wIndex;
    if (doLogging) _startDatasetMsg('Item Defined', null, item.vfLength, item);
    _wb
      ..writeCode(kItem, 8 + item.vfLength)
      ..writeUint32(0);
    final mark = _wb.wIndex;
    final vlfOffset = mark - 4;
    _writeDataset(item);
    final vfLength = _wb.wIndex - mark;
    assert(vfLength.isEven && _wb.wIndex.isEven);
    // Now that vfLength is known write it at vflOffset.
    _wb.bytes.setUint32(vlfOffset, vfLength);
    if (doLogging) _endDatasetMsg(start, 'Item Defined', item.dsBytes);
  }

  void _writeUndefinedLengthItem(Item item) {
    final start = _wb.wIndex;
    if (doLogging)
      _startDatasetMsg('Item Undefined', kItemDelimitationItem, -1, item);
    _wb
      ..writeCode(kItem, 8)
      ..writeUint32(kUndefinedLength);
    _writeDataset(item);
    _wb
      ..writeCode(kItemDelimitationItem, 8)
      ..writeUint32(0);
    if (doLogging) _endDatasetMsg(start, 'Item Undefined', item.dsBytes);
  }

  /// Writes Encapsulated Pixel Data without Fragments
  void _writeEncapsulatedPixelData(Element e) {
    assert(e.code == kPixelData && e.vfLengthField == kUndefinedLength);
    if (e.frames is! CompressedFrameList) {
      badElement('Not Pixel Data: $e');
      return;
    }
    final offsets = e.offsets;
    final vfLength = offsets.lengthInBytes;
    final bulkdata = e.bulkdata;
    final bdLength = bulkdata.lengthInBytes;
    _wb
      ..writeCode(kItem, 8 + vfLength)
      ..writeUint32(vfLength)
      ..writeUint32List(offsets)
      ..writeCode(kItem, 8 + bdLength)
      ..writeUint32(bdLength)
      ..writeUint8List(bulkdata);
  }

  void _writeFragments(Element e) {
    assert(e.vfLengthField == kUndefinedLength && e.code == kPixelData);
    for (final fragment in e.fragments.fragments) {
      final length = fragment.lengthInBytes;
      _wb
        ..writeCode(kItem, 8 + length)
        ..writeUint32(length)
        ..writeUint8List(fragment);

      // If odd length write padding byte
      if (fragment.length.isOdd) {
        log.warn('** Odd length(${fragment.lengthInBytes}) fragment');
        _wb.writeUint8(0);
      }
    }
  }

  // **** Common methods

  bool _isSequenceVR(int vrIndex) => vrIndex == kSQIndex;

  bool _isSpecialVR(int vrIndex) =>
      vrIndex >= kOBOWIndex && vrIndex <= kUSSSIndex;

  bool _isMaybeUndefinedLengthVR(int vrIndex) =>
      vrIndex >= kUNIndex && vrIndex <= kOWIndex;

  bool _isEvrLongDefinedLengthVR(int vrIndex) =>
      vrIndex >= kODIndex && vrIndex <= kUTIndex;

  bool _isIvrDefinedLengthVR(int vrIndex) =>
      vrIndex >= kODIndex && vrIndex <= kUSIndex;

  bool _isEvrShortVR(int vrIndex) => vrIndex >= kAEIndex && vrIndex <= kUSIndex;

  bool _isNotShortVR(int vrIndex) => !_isEvrShortVR(vrIndex);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void _writeLongDefinedLength(Element e, [int vrIndex]) {
    assert(e.vfLengthField != kUndefinedLength && _wb.wIndex.isEven);
    final start = _wb.wIndex;
    if (doLogging) _startElementMsg(e);
    _writeLongDefinedLengthHeader(e, vrIndex, e.vfLength);
    _writeValueField(e, vrIndex);
    if (doLogging) _endElementMsg(start, e);
  }

  /// Write a non-Sequence Element (OB, OW, UN) that may have
  /// an undefined length.
  void _writeMaybeUndefinedLength(Element e, [int vrIndex]) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeLongUndefinedLength(e, vrIndex)
          : _writeLongDefinedLength(e, vrIndex);

  /// Write a non-Sequence _undefined length_ Element.
  void _writeLongUndefinedLength(Element e, int vrIndex) {
    final start = _wb.wIndex;
    if (doLogging) _startElementMsg(e);
    assert(_isMaybeUndefinedLengthVR(vrIndex) &&
        e.vfLengthField == kUndefinedLength &&
        _wb.wIndex.isEven);

    __writeLongUndefinedLengthHeader(e, vrIndex);
    if (e.code == kPixelData) {
      if (rds.transferSyntax.isEncapsulated) {
        _writeFragments(e);
      } else {
        _writeEncapsulatedPixelData(e);
      }
    } else {
      _writeValueField(e, vrIndex);
    }
    _wb
      ..writeCode(kSequenceDelimitationItem, 8)
      ..writeUint32(0);

    assert(_wb.wIndex.isEven);
    if (doLogging) _endElementMsg(start, e);
  }

  /// Write a Sequence Element.
  void _writeSequence(Element sq, int vrIndex) {
    final start = _wb.wIndex;
    if (doLogging) _startSQMsg(sq);
    final doConvert = eParams.doConvertUndefinedLengths;
    if (sq.isEmpty && doConvert) {
      _writeLongDefinedLengthHeader(sq, vrIndex, 0);
    } else if (!doConvert && (sq.vfLengthField == kUndefinedLength)) {
      _writeSQUndefinedLength(sq, vrIndex);
    } else {
      _writeSQDefinedLength(sq, vrIndex);
    }
    if (doLogging) _endSQMsg(start, sq);
  }

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQDefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && (vrIndex == kSQIndex || vrIndex == kUNIndex), '$e');
    _writeLongDefinedLengthHeader(e, vrIndex, 0);
    final vfStart = _wb.wIndex;
    assert(vfStart.isEven);
    // This if the offset where the vfLengthField will be written
    final vlfOffset = vfStart - 4;
    _writeItems(e.items);
    final vfLength = _wb.wIndex - vfStart;
    assert(
        vfLength.isEven && _wb.wIndex.isEven && vfLength != kUndefinedLength);
    // Now that vfLength is known write it at vflOffset.
    _wb.bytes.setUint32(vlfOffset, vfLength);
  }

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQUndefinedLength(SQ e, int vrIndex, {bool doConvertUN = false}) {
    // Urgent: what to do here
    assert(
        (e is SQ || e is UN) && (vrIndex == kSQIndex || vrIndex == kUNIndex));
    assert(_wb.wIndex.isEven);
    __writeLongUndefinedLengthHeader(e, doConvertUN ? kSQIndex : vrIndex);
    if (e.items.isNotEmpty) _writeItems(e.items);
    _wb
      ..writeCode(kSequenceDelimitationItem, 8)
      ..writeUint32(0);
    assert(_wb.wIndex.isEven);
  }

  /// Write a Long Header with Value Length Field equal to [e].vfLength.
  bool _writeLongDefinedLengthHeader(Element e, int vrIndex, int vfLength) {
    assert(e != null && _wb.wIndex.isEven);
    assert(vfLength != null);
    final isOddLength = vfLength.isOdd;
    final length = vfLength + (isOddLength ? 1 : 0);
    assert(length.isEven);
    assert(length >= 0 && length < kUndefinedLength, 'length: $length');
    __writeLongDefinedLengthHeader(e, vrIndex, length);
    assert(_wb.wIndex.isEven);
    return isOddLength;
  }

  void _writeValueField(Element e, int vrIndex) {
    print('e: $e');
    assert(_wb.wIndex.isEven);
    _wb.write(e.vfBytes);
    if (e.vfBytes.length.isOdd) _writePaddingChar(e, vrIndex);
    assert(_wb.wIndex.isEven);
  }

  void _writePaddingChar(Element e, int vrIndex) {
    assert(_wb.wIndex.isOdd, 'wb.index: ${_wb.wIndex} - $e');
//    assert(e.vfLength.isOdd, 'vfLength: ${e.vfLength} - $e');
    final padChar = paddingChar(vrIndex);
    if (padChar.isNegative) {
      log.error('Padding a non-padded Element: $e');
      invalidValueField('vfLength(${e.vfLength}) is odd integer', e.vfBytes);
    }
    if (doLogging) log.debug('** writing pad char: $padChar');
    _wb.writeUint8(padChar);
    assert(_wb.wIndex.isEven);
  }

  String _vlfString(int vlf) =>
      (vlf == kUndefinedLength) ? '**Undefined Length**' : 'vfl: $vlf';

  String _range(int start, int end) {
    final length = end - start;
    return '$start-$end:$length';
  }

  void _startElementMsg(Element e) {
    final vfl = e.vfLength;
    final vlf = e.vfLengthField;
    final len =
        (vlf == kUndefinedLength) ? 'Undefined Length ($vfl)' : 'vfl($vfl)';
    log
      ..debug('>@W${_wb.wIndex} ${e.runtimeType} $e : $len')
      ..down;
  }

  void _endElementMsg(int start, Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    final end = _wb.wIndex;
    final range = _range(start, end);
    log
      ..up
      ..debug('<@W$end ${e.runtimeType} #$eNumber $range');
  }

  void _startSQMsg(Element sq) {
    final msg = '>@W${_wb.wIndex} ${sq.runtimeType} $sq';
    log
      ..debug(msg)
      ..down;
  }

  void _endSQMsg(int start, Element sq) {
    final eNumber = '$count'.padLeft(4, '0');
    final end = _wb.wIndex;
    final range = _range(start, end);
    final msg = '<@W$end ${sq.runtimeType} #$eNumber: $range';
    log
      ..up
      ..debug(msg);
  }

  void _startDatasetMsg(String name, int delimiter, int vlf, Dataset ds) {
    final s = _vlfString(vlf);
    log
      ..debug('>@W${_wb.wIndex} $name $ds $s')
      ..down;
  }

  void _endDatasetMsg(int start, String name, DSBytes dsBytes) {
    final end = _wb.wIndex;
    final range = _range(start, end);
    log
      ..up
      ..debug('<@W$end $name: $range $dsBytes');
  }

  String get endianness => (_wb.endian == Endian.little) ? 'Little' : 'Big';

  void _startRootDatasetMsg(int start, RootDataset ds, TransferSyntax ts) {
    log
      ..debug('| Logging ($endianness Endian)...')
      ..down
      ..debug('>@W$start write $ds ${_wb.length} bytes')
      ..down;
  }

  void _endRootDatasetMsg(int start, RootDataset rds, DSBytes dsBytes) {
    final eNumber = '$count'.padLeft(4, '0');
    final end = _wb.wIndex;
    final range = _range(start, end);
    log
      ..debug('<@W$end ${rds.runtimeType} $range')
      ..up
      ..debug('| $endianness Endian')
      ..debug('| $dsBytes')
      ..debug('| ${_wb.buffer}')
      ..debug('| $eNumber Elements written')
      ..up
      ..debug('<@W$end RootDataset: $range');
  }

  /// Write a Sequence Element.
  void writeSequence(SQ e, [int vrIndex]) => _writeSequence(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQDefinedLength(SQ e, [int vrIndex]) =>
      _writeSQDefinedLength(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQUndefinedLength(SQ e, [int vrIndex]) =>
      _writeSQUndefinedLength(e, vrIndex);
}

Endian getEndianness(RootDataset rds, [TransferSyntax outputTS]) =>
    (outputTS == null) ? rds.transferSyntax.endian : outputTS.endian;

const _k1MB = 1024 * 1024;

/// The default [Bytes] buffer length, if none is provided.
const int kDefaultWriteBufferLength = _k1MB; //200 * k1MB;

bool reUseWriteBuffer = false;

/// A reusable  [DicomWriteBuffer] is stored here.
DicomWriteBuffer _reUseBuffer;

DicomWriteBuffer getWriteBuffer([int length]) {
  if (!reUseWriteBuffer || _reUseBuffer == null) {
    _reUseBuffer = DicomWriteBuffer.empty(length);
  } else if (length > _reUseBuffer.length) {
    _reUseBuffer = DicomWriteBuffer.empty(length + 1024);
    log.warn('** DcmSubWriterBase creating new Reuse BD of Size: '
        '${_reUseBuffer.length}');
  } else {
    _reUseBuffer.reset;
  }
  return _reUseBuffer;
}

abstract class EvrSubWriter extends SubWriter with FmiMixin {
  @override
  final bool isEvr = true;

  EvrSubWriter(
      RootDataset rds, EncodingParameters eParams, TransferSyntax outputTS,
      [int length])
      : super(rds, eParams, outputTS, length);

  /// Write an EVR [Element].
  @override
  void _writeElement(Element e, [int vrIndex]) {
    vrIndex ??= e.vrIndex;
    assert(e != null && !_isSpecialVR(vrIndex), 'Invalid VR: $vrIndex');
    _count++;

    if (_isEvrShortVR(vrIndex)) {
      _writeShort(e, vrIndex);
    } else if (_isEvrLongDefinedLengthVR(vrIndex)) {
      _writeLongDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      _writeSequence(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw ArgumentError('Invalid VRIndex($vrIndex): $e');
    }
  }

  /// Write an EVR Element with a short Value Length field.
  void _writeShort(Element e, int vrIndex) {
    assert(_wb.wIndex.isEven);
    assert(e.vfLengthField != kUndefinedLength && _wb.wIndex.isEven);
    final start = _wb.wIndex;
    if (doLogging) _startElementMsg(e);

    final vfLength = e.vfLength + (e.vfLength.isOdd ? 1 : 0);
    assert(vfLength.isEven);
    assert(vfLength >= 0 && vfLength <= kMaxShortVF, 'length: $vfLength');
    _writeShortHeader(e, vrIndex, vfLength);
    assert(_wb.wIndex.isEven);
    _writeValueField(e, vrIndex);
    if (doLogging) _endElementMsg(start, e);
  }

  void _writeShortHeader(Element e, int vrIndex, int vfLength) {
    assert(_isEvrShortVR(vrIndex));
    final vrCode = e.vrCode;
    _wb
      ..writeCode(e.code, 8 + vfLength)
      ..writeUint8(vrCode >> 8)
      ..writeUint8(vrCode & 0xFF)
      ..writeUint16(vfLength);
  }

  @override
  void __writeLongDefinedLengthHeader(
      Element e, int vrIndex, int vfLengthField) {
    assert(vfLengthField != kUndefinedLength);
    assert(vfLengthField >= 0 && vfLengthField <= kMaxLongVF);
    final vlf = (vfLengthField.isOdd) ? vfLengthField + 1 : vfLengthField;
    __writeLongHeader(e, vrIndex, vlf);
  }

  @override
  void __writeLongUndefinedLengthHeader(Element e, int vrIndex) {
    assert(_isMaybeUndefinedLengthVR(vrIndex) || vrIndex == kSQIndex, '$e');
    __writeLongHeader(e, vrIndex, kUndefinedLength);
  }

  /// Write a Long EVR [Element], i.e. with 32-bit Value Field Length field.
  void __writeLongHeader(Element e, int vrIndex, int vfLength) {
    assert(_isNotShortVR(vrIndex), 'vrIndex: $vrIndex');
    final vrCode = e.vrCode;
    _wb
      ..writeCode(e.code, 12)
      ..writeUint8(vrCode >> 8)
      ..writeUint8(vrCode & 0xFF)
      ..writeUint16(0)
      ..writeUint32(vfLength);
  }
}

/// A class that writes IVR Elements.
abstract class IvrSubWriter extends SubWriter {
  @override
  final bool isEvr = false;

  IvrSubWriter.from(EvrSubWriter subWriter) : super.from(subWriter);

  /// Write an IVR [Element].
  @override
  void _writeElement(Element e, [int vrIndex]) {
    vrIndex ??= e.vrIndex;
    assert(e != null && !_isSpecialVR(vrIndex), 'Invalid VR: $vrIndex');
    _count++;

    if (e is SQ || _isSequenceVR(vrIndex)) {
      _writeSequence(e, vrIndex);
    } else if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeLongDefinedLength(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw ArgumentError('Invalid VR($vrIndex): $e');
    }
  }

  /// Write a Long IVR [Element] header,
  /// i.e. with 32-bit Value Field Length field.
  ///
  /// _Note_: all IVR Headers have 32-bit Value Field Length field.
  @override
  void __writeLongDefinedLengthHeader(Element e, int _, int vfLength) {
    assert(vfLength >= 0 && vfLength <= kMaxLongVF);
    final vlf = (vfLength.isOdd) ? vfLength + 1 : vfLength;
    _wb
      ..writeCode(e.code, 12 + vfLength)
      ..writeUint32(vlf);
  }

  @override
  void __writeLongUndefinedLengthHeader(Element e, int vrIndex) {
    assert(e.vfLengthField == kUndefinedLength, '${e.vfLengthField}');
    assert(_isMaybeUndefinedLengthVR(vrIndex), 'vrIndex: $vrIndex');
    _wb
      // 12 + 8 = header + sequence delimiter
      ..writeCode(e.code, 20)
      ..writeUint32(kUndefinedLength);
  }
}

/// Write File Meta Information (FMI)
mixin FmiMixin {
  RootDataset get rds;
  EncodingParameters get eParams;
  DicomWriteBuffer get _wb;
  int get count;
  bool get doLogging;
  void _writeElement(Element e, [int vrIndex]);

  // **** End of Interface ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  int writeFmi() {
    if (doLogging)
      log
        ..debug('>@${_wb.wIndex} Writing Root Dataset')
        ..down
        ..debug('>@W${_wb.wIndex} Writing ${rds.fmi.length} FMI Elements ...')
        ..down;

    if (rds.hasFmi) {
      if (eParams.doUpdateFMI) {
        _writeOdwFmi();
      } else {
        _writeExistingFmi(cleanPreamble: eParams.doCleanPreamble);
      }
    } else {
      if (eParams.doAddMissingFMI) {
        _writeOdwFmi();
      } else if (!eParams.allowMissingFMI) {
        log.warn('** Dataset $rds is missing FMI elements');
        return 0;
      }
    }

    if (doLogging) {
      log
        ..up
        ..debug('<W@${_wb.wIndex} FinishedWriting FMI: $count Elements written')
        ..up
        ..debug('|@${_wb.wIndex} TS: ${rds.transferSyntax}');
    }
    return _wb.wIndex;
  }

  void _writeOdwFmi() {
    _writeEmptyPreambleAndPrefix();
    _writeFmiElements();
  }

  void _writeExistingFmi({bool cleanPreamble = true}) {
    _writePreambleAndPrefix(rds, cleanPreamble: cleanPreamble);
    _writeFmiElements();
  }

  void _writeFmiElements() {
    for (final e in rds.fmi.elements) {
      if (e.code > 0x00030000) break;
      _writeElement(e);
    }
  }

  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool _writePreambleAndPrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    final v = (rds.prefix == Bytes.kEmptyBytes || eParams.doCleanPreamble)
        ? _writeEmptyPreambleAndPrefix()
        : _writeExistingPreambleAndPrefix();
    if (doLogging) log.info('|@W${_wb.wIndex} Preamble and Prefix written');
    return v;
  }

  /// Writes a new Open DICOMweb FMI.
  bool _writeExistingPreambleAndPrefix() {
    assert(rds.prefix != Bytes.kEmptyBytes && !eParams.doCleanPreamble);
    final preamble = rds.preamble;
    for (var i = 0; i < 128; i++) _wb.writeUint8(preamble.getUint8(i));
    return __writePrefix();
  }

  bool _writeEmptyPreambleAndPrefix() {
    _wb.writeZeros(128);
    return __writePrefix();
  }

  bool __writePrefix() {
    _wb.writeUint8List(kPrefixAsList);
    print('prefix: ${_wb.bytes.asUint8List(128, 4)}');
    return true;
  }
}
