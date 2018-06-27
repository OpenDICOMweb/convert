//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/padding_chars.dart';
import 'package:convert/src/element_offsets.dart';
import 'package:convert/src/encoding_parameters.dart';

//Urgent Jim: add to EvrULength at appropriate places

typedef void ElementSubWriter(Element e);

/// Default allocation is 16K bytes
const int kMinWriteBufferLength = 0x4000;

abstract class EvrSubWriter extends SubWriter {
  @override
  final bool isEvr = true;

  EvrSubWriter(
      RootDataset rds, EncodingParameters eParams, TransferSyntax outputTS,
      [int length])
      : super(rds, eParams, outputTS, length);

  /// Write an EVR [Element].
  @override
  void _writeElement(Element e, [int vrIndex]) {
    assert(e != null);
    final start = _wb.index;
    if (doLogging) _startElementMsg(start, e);
    vrIndex ??= e.vrIndex;
    assert(!_isSpecialVR(vrIndex), 'Invalid VR: $vrIndex');

    if (_isEvrShortVR(vrIndex)) {
      _writeShort(e, vrIndex);
    } else if (_isLongDefinedLengthVR(vrIndex)) {
      _writeLongDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      _writeSequence(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VRIndex($vrIndex): $e');
    }

    _count++;
    if (doLogging) _endElementMsg(start, e);
  }

  /// Write an EVR Element with a short Value Length field.
  void _writeShort(Element e, int vrIndex) {
    assert(e.vfLengthField != kUndefinedLength && _wb.index.isEven);
    final vfLength = e.vfLength + (e.vfLength.isOdd ? 1 : 0);
    assert(vfLength.isEven);
    assert(vfLength >= 0 && vfLength <= kMaxShortVF, 'length: $vfLength');
    _writeShortHeader(e, vrIndex, vfLength);
    _writeValueField(e, vrIndex);
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
  void __writeLongDefinedLengthHeader(Element e, int vrIndex, int vfLength) {
    assert(vfLength != kUndefinedLength);
    assert(vfLength >= 0 && vfLength <= kMaxLongVF);
    final vlf = (vfLength.isOdd) ? vfLength + 1 : vfLength;
    __writeLongHeader(e, vrIndex, vlf);
  }

  @override
  void __writeLongUndefinedLengthHeader(Element e, int vrIndex) {
    assert(_isMaybeUndefinedLengthVR(vrIndex) || vrIndex == kSQIndex, '$e');
    __writeLongHeader(e, vrIndex, kUndefinedLength);
  }

  /// Write a Long EVR [Element], i.e. with 32-bit Value Field Length field.
  void __writeLongHeader(Element e, int vrIndex, int vfLengthField) {
    assert(_isNotShortVR(vrIndex), 'vrIndex: $vrIndex');
    final vrCode = e.vrCode;
    _wb
      ..writeCode(e.code, 12 + e.vfLength)
      ..writeUint8(vrCode >> 8)
      ..writeUint8(vrCode & 0xFF)
      ..writeUint16(0)
      ..writeUint32(vfLengthField);
  }

  // **** Write File Meta Information (FMI) ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  int writeFmi() {
    if (doLogging)
      log
        ..debug('>@${_wb.index} Writing Root Dataset')
        ..debug('|@${_wb.index} ${rds.transferSyntax}')
        ..down
        ..debug('>@W${_wb.index} Writing ${rds.fmi.length} FMI Elements ...')
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
        log.warn('Dataset $rds is missing FMI elements');
        return 0;
      }
    }

    if (doLogging) {
      log
        ..up
        ..debug('<W@${_wb.index} FinishedWriting FMI: $count Elements written')
        ..up;
    }
    return _wb.wIndex;
  }

  void _writeOdwFmi() {
    _writeEmptyPreambleAndPrefix();
    //Urgent finish
  }

  void _writeExistingFmi({bool cleanPreamble = true}) {
    _writePreambleAndPrefix(rds, cleanPreamble: cleanPreamble);
    for (var e in rds.fmi.elements) {
      if (e.code > 0x00030000) break;
      _writeElement(e);
    }
  }

  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool _writePreambleAndPrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    final v = (rds.prefix == kEmptyBytes || eParams.doCleanPreamble)
        ? _writeEmptyPreambleAndPrefix()
        : _writeExistingPreambleAndPrefix();
    if (doLogging) log.info('|@W${_wb.index} Preamble and Prefix written');
    return v;
  }

  /// Writes a new Open DICOMweb FMI.
  bool _writeExistingPreambleAndPrefix() {
    assert(rds.prefix != kEmptyBytes && !eParams.doCleanPreamble);
    final preamble = rds.preamble;
    for (var i = 0; i < 128; i++) _wb.writeUint8(preamble.getUint8(i));
    return __writePrefix();
  }

  bool _writeEmptyPreambleAndPrefix() {
    _wb.writeZeros(128);
    return __writePrefix();
  }

  bool __writePrefix() {
    _wb.writeUint32(kDcmPrefix);
    return true;
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
    final start = _wb.index;
    if (doLogging) _startElementMsg(start, e);
    vrIndex ??= e.vrIndex;
    assert(e != null && !_isSpecialVR(vrIndex), 'Invalid VR: $vrIndex');

    if (e is SQ || _isSequenceVR(vrIndex)) {
      _writeSequence(e, vrIndex);
    } else if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeLongDefinedLength(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VR($vrIndex): $e');
    }

    if (doLogging) _endElementMsg(start, e);
    _count++;
  }

  bool _isIvrDefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRDefinedLongIndexMin && vrIndex <= kVRIvrLongIndexMax;

  /// Write a Long IVR [Element] header,
  /// i.e. with 32-bit Value Field Length field.
  ///
  /// _Note_: all IVR Headers have 32-bit Value Field Length field.
  @override
  void __writeLongDefinedLengthHeader(Element e, int _, int vfLength) {
    assert(vfLength >= 0 && vfLength <= kMaxLongVF);
    final vlf = (vfLength.isOdd) ? vfLength + 1 : vfLength;
    _wb
      ..writeCode(e.code, 12 + vlf)
      ..writeUint32(vlf);
  }

  @override
  void __writeLongUndefinedLengthHeader(Element e, int vrIndex) {
    assert(e.vfLengthField == kUndefinedLength, '${e.vfLengthField}');
    assert(_isMaybeUndefinedLengthVR(vrIndex), 'vrIndex: $vrIndex');
    _wb
      ..writeCode(e.code, 12 + e.vfLength)
      ..writeUint32(kUndefinedLength);
  }
}

abstract class SubWriter {
  /// The current [Dataset].
  Dataset cds;

  /// [Encoding Parameters]
  final EncodingParameters eParams;

  /// The [TransferSyntax] to be written.
  final TransferSyntax outputTS;

  /// The [DicomWriteBuffer] currently being written.
  DicomWriteBuffer _wb;

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
  Bytes get output => _wb.view();

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
  Bytes writeRootDataset([int fmiEnd, TransferSyntax ts]) {
    final dsStart = _wb.index;
    if (doLogging) _startRootDatasetMsg(dsStart, rds, ts);
    _wb.buffer.endian = (ts.isBigEndian) ? Endian.big : Endian.little;
    _writeDataset(rds);
    final bytes = _wb.sublist(0, _wb.wIndex);
    final dsBytes = new RDSBytes(bytes, fmiEnd);
    rds.dsBytes = dsBytes;
    if (doLogging) _endRootDatasetMsg(dsStart, dsBytes);
    return bytes;
  }

  /// Writes a [Dataset] to the output.
  void _writeDataset(Dataset ds) {
    // ignore: prefer_forEach
    for (var e in ds.elements) _writeElement(e);
  }

  /// Write all [Item]s in [items].
  void _writeItems(List<Item> items) {
    for (var item in items) {
      final parentDS = cds;
      cds = item;
      _writeItem(item);
      cds = parentDS;
    }
  }

  /// Write one [Item].
  void _writeItem(Item item) {
    final iStart = _wb.index;
    if (doLogging) _startItemMsg(iStart, item);
    (item.hasULength && !eParams.doConvertUndefinedLengths)
        ? _writeUndefinedLengthItem(item)
        : _writeDefinedLengthItem(item);
    if (doLogging) _endItemMsg(iStart, item.dsBytes);
  }

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthItem(Item item) {
    _wb
      ..writeCode(kItem, item.length)
      ..writeUint32(item.vfLength);
    _writeDataset(item);
  }

  void _writeUndefinedLengthItem(Item item) {
    _wb
      ..writeCode(kItem)
      ..writeUint32(kUndefinedLength);
    _writeDataset(item);
    _wb
      ..writeCode(kItemDelimitationItem)
      ..writeUint32(0);
  }

  /// Writes Encapsulated Pixel Data without Fragments
  void _writeEncapsulatedPixelData(PixelData e) {
    assert(e.vfLengthField == kUndefinedLength);
    final offsets = e.offsets;
    final bulkdata = e.bulkdata;
    if (e.frames is CompressedFrameList) {
      _wb
        ..writeCode(kItem, 8 +  e.frames.length)
        ..writeUint32(e.offsets.lengthInBytes)
        ..writeUint32List(offsets)
        ..writeCode(kItem, bulkdata.lengthInBytes)
        ..writeUint32(bulkdata.lengthInBytes)
        ..writeUint8List(bulkdata);
    } /*else {
      _wb
        ..writeCode(kItem, 8 + frames.lengthInBytes)
        ..writeUint32(0)
        ..writeCode(kItem, frames.bulkdata.lengthInBytes)
        ..writeUint32(frames.bulkdata.lengthInBytes)
        ..writeUint8List(frames.bulkdata);
    }
*/
  }

  void _writeFragments(BytePixelData e) {
    assert(e.vfLengthField == kUndefinedLength);
    for (final fragment in e.fragments.fragments) {
      _wb
        ..writeCode(kItem, 12 + e.vfLength)
        ..writeUint32(fragment.lengthInBytes)
        ..writeUint8List(fragment);

      // If odd length write padding byte
      if (fragment.length.isOdd) {
        log.warn('Odd length(${fragment.lengthInBytes}) fragment');
        _wb.writeUint8(0);
      }
    }
  }

  // **** Common methods

  bool _isSequenceVR(int vrIndex) => vrIndex == 0;

  bool _isSpecialVR(int vrIndex) =>
      vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

  bool _isMaybeUndefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRMaybeUndefinedIndexMin &&
      vrIndex <= kVRMaybeUndefinedIndexMax;

  bool _isLongDefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRDefinedLongIndexMin && vrIndex <= kVREvrLongIndexMax;

  bool _isEvrShortVR(int vrIndex) =>
      vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

  bool _isNotShortVR(int vrIndex) => !_isEvrShortVR(vrIndex);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void _writeLongDefinedLength(Element e, [int vrIndex]) {
    assert(e.vfLengthField != kUndefinedLength && _wb.index.isEven);
    _writeLongDefinedLengthHeader(e, vrIndex);
    _writeValueField(e, vrIndex);
  }

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void _writeMaybeUndefinedLength(Element e, [int vrIndex]) {
    (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeLongUndefinedLength(e, vrIndex)
        : _writeLongDefinedLength(e, vrIndex);
  }

  /// Write a non-Sequence _undefined length_ Element.
  void _writeLongUndefinedLength(Element e, int vrIndex) {
    assert(_isMaybeUndefinedLengthVR(vrIndex) &&
        e.vfLengthField == kUndefinedLength &&
        _wb.index.isEven);
    __writeLongUndefinedLengthHeader(e, vrIndex);
    if (e.code == kPixelData) {
      if (e is BytePixelData) {
        _writeFragments(e);
      } else {
        _writeEncapsulatedPixelData(e);
      }
    } else {
      _writeValueField(e, vrIndex);
    }
    _wb
      ..writeCode(kSequenceDelimitationItem)
      ..writeUint32(0);
    assert(_wb.wIndex.isEven);
  }

  /// Write a Sequence Element.
  void _writeSequence(Element sq, int vrIndex) {
    final start = _wb.index;
    if (doLogging) _startSQMsg(start, sq);
    if (sq.vfLengthField == 0) {
      _writeLongDefinedLength(sq, vrIndex);
    } else if (sq.hadULength && !eParams.doConvertUndefinedLengths) {
      _writeSQUndefinedLength(sq, vrIndex);
    } else {
      _writeSQDefinedLength(sq, vrIndex);
    }
    if (doLogging) _endSQMsg(start);
  }

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQDefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && (vrIndex == kSQIndex || vrIndex == kUNIndex), '$e');
    final eStart = _wb.wIndex;
    assert(eStart.isEven);
    _writeLongDefinedLengthHeader(e, vrIndex);
    // This if the offset where the vfLengthField will be written
    final vlfOffset = _wb.wIndex - 4;
    _writeItems(e.items);
    final vfOffset = isEvr ? 12 : 8;
    final vfLength = (_wb.wIndex - eStart) - vfOffset;
    assert(vfLength.isEven && _wb.wIndex.isEven);
    // Now that vfLength is known write it at vflOffset.
    _wb.buffer.setUint32(vlfOffset, vfLength);
  }

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQUndefinedLength(SQ e, int vrIndex) {
    assert(e is SQ);
    assert(_wb.index.isEven);
    __writeLongUndefinedLengthHeader(e, vrIndex);
    _writeItems(e.items);
    _wb
      ..writeCode(kSequenceDelimitationItem)
      ..writeUint32(0);
    assert(_wb.wIndex.isEven);
  }

  /// Write a Long Header with Value Length Field equal to [e].vfLength.
  bool _writeLongDefinedLengthHeader(Element e, int vrIndex) {
    assert(e != null && _wb.wIndex.isEven);
    final vfLength = e.vfLength;
    assert(vfLength != null);
    final isOddLength = vfLength.isOdd;
    final length = vfLength + (isOddLength ? 1 : 0);
    assert(length.isEven);
    assert(length >= 0 && length < kUndefinedLength, 'length: $length');
    __writeLongDefinedLengthHeader(e, vrIndex, length);
    assert(_wb.index.isEven);
    return isOddLength;
  }

  void _writeValueField(Element e, int vrIndex) {
    assert(_wb.wIndex.isEven);
    _wb.write(e.vfBytes);
    if (e.vfLength.isOdd) _writePaddingChar(e, vrIndex);
    assert(_wb.wIndex.isEven);
  }

  void _writePaddingChar(Element e, int vrIndex) {
    assert(_wb.wIndex.isOdd, 'vfLength: ${e.vfLength} - $e');
    final padChar = paddingChar(vrIndex);
    if (padChar.isNegative) {
      log.error('Padding a non-padded Element: $e');
      invalidValueField('vfLength(${e.vfLength}) is odd integer', e.vfBytes);
    }
    if (doLogging) log.debug2('** writing pad char: $padChar');
    _wb.writeUint8(padChar);
    assert(_wb.wIndex.isEven);
  }

  String _vlfString(int vlf) =>
      (vlf == kUndefinedLength) ? '**Undefined Length**' : 'vfl: $vlf';

  String _range(int start, int end) {
    final length = end - start;
    return '$start-$end:$length';
  }

  void _startElementMsg(int start, Element e) {
    final vfl = e.vfLength;
    final vlf = e.vfLengthField;
    final len =
        (vlf == kUndefinedLength) ? 'Undefined Length ($vfl)' : 'vfl($vfl)';
    log
      ..debug('>@W$start ${e.runtimeType} $e : $len')
      ..down;
  }

  void _endElementMsg(int start, Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    final end = _wb.index;
    final range = _range(start, end);
    log
      ..up
      ..debug('<@W$end ${e.runtimeType} #$eNumber $range');
  }

  void _startSQMsg(int start, Element sq) {
    final msg = '>@W$start ${sq.runtimeType} $sq';
    log
      ..debug(msg)
      ..down;
  }

  void _endSQMsg(int start) {
    final eNumber = '$count'.padLeft(4, '0');
    final end = _wb.index;
    final range = _range(start, end);
    final msg = '<@W$end #$eNumber: $range';
    log
      ..up
      ..debug(msg);
  }

  void _startItemMsg(int start, Item item) {
    final vlf = _vlfString(item.vfLengthField);
    log
      ..debug('>@W$start writeItem $item $vlf')
      ..down;
  }

  void _endItemMsg(int start, DSBytes dsBytes) {
    final end = _wb.index;
    final range = _range(start, end);
    log
      ..up
      ..debug('<@W$end writeItem: $range $dsBytes');
  }

  String get endianness => (_wb.endian == Endian.little) ? 'Little' : 'Big';

  void _startRootDatasetMsg(int start, RootDataset ds, TransferSyntax ts) {
    log
      ..debug('| Logging ($endianness Endian)...')
      ..down
      ..debug('>@W$start write $ds ${_wb.length} bytes')
      ..down;
  }

  void _endRootDatasetMsg(int start, DSBytes dsBytes) {
    final eNumber = '$count'.padLeft(4, '0');
    final end = _wb.index;
    final range = _range(start, end);
    log
      ..up
      ..debug('| $endianness Endian')
      ..debug('| $dsBytes')
      ..debug('| ${_wb.buffer}')
      ..debug('| $eNumber Elements written')
      ..debug('<@W$end writeRootDataset: $range');
  }

/* Flush if not used
  void writePrivateInformation(Uid uid, Bytes privateInfo) {
    _wb.ascii(uid.asString);
  }
*/

  // **** External interface for debugging and monitoring

/*
// Urgent: decide on best way to handle this
//  void writeElement(Element e) => _writeElement(e);

  Bytes writeRootDataset([int fmiEnd]) => _writeRootDataset(fmiEnd);

  void writeExistingFmi({bool cleanPreamble = true}) =>
      _writeExistingFmi(cleanPreamble: cleanPreamble);
  Bytes writeOdwFmi() => _writeOdwFmi();

  void writeItems(List<Item> items) => _writeItems(items);

  void writeItem(Item item) => _writeItem(item);
  void writeDefinedLengthItem(Item item) => _writeDefinedLengthItem(item);
  void writeUndefinedLengthItem(Item item) => _writeUndefinedLengthItem(item);

  /// Write an EVR Element with a short Value Length field.
  void writeElement(Element e, [int vrIndex]) => _writeElement(e, vrIndex);

  /// Write an EVR Element with a short Value Length field.
  void writeShortElement(Element e, [int vrIndex]) => _writeShort(e, vrIndex);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void writeLongElement(Element e, [int vrIndex]) =>
      _writeLongDefinedLength(e, vrIndex);

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void writeMaybeUndefinedLengthElement(Element e, [int vrIndex]) =>
      _writeMaybeUndefinedLength(e, vrIndex);
*/

/*
  /// Write a non-Sequence _undefined length_ Element.
  void writeLongUndefinedLength(Element e, [int vrIndex]) =>
      _writeLongUndefinedLength(e, vrIndex);
*/

  /// Write a Sequence Element.
  void writeSequence(SQ e, [int vrIndex]) => _writeSequence(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQDefinedLength(SQ e, [int vrIndex]) =>
      _writeSQDefinedLength(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQUndefinedLength(SQ e, [int vrIndex]) =>
      _writeSQUndefinedLength(e, vrIndex);

/*
  // Urgent delete or Move Elsewhere if needed
  /// Returns the [outputTS] for the encoded output.
  static TransferSyntax getOutputTS(RootDataset rds, TransferSyntax outputTS) {
    if (outputTS == null) {
      return (rds.transferSyntax == null)
          ? global.defaultTransferSyntax
          : rds.transferSyntax;
    } else {
      return outputTS;
    }
  }
*/

}

Endian getEndianness(RootDataset rds, [TransferSyntax outputTS]) =>
    (outputTS == null) ? rds.transferSyntax.endian : outputTS.endian;

/// The default [Bytes] buffer length, if none is provided.
const int kDefaultWriteBufferLength = k1MB; //200 * k1MB;

bool reUseWriteBuffer = true;

/// A reusable  [DicomWriteBuffer] is stored here.
DicomWriteBuffer _reUseBuffer;

DicomWriteBuffer getWriteBuffer([int length]) {
  length ??= kDefaultWriteBufferLength;
  if (!reUseWriteBuffer || _reUseBuffer == null) {
    _reUseBuffer = new DicomWriteBuffer(length);
  } else if (length > _reUseBuffer.length) {
    _reUseBuffer = new DicomWriteBuffer(length + 1024);
    log.warn('**** DcmSubWriterBase creating new Reuse BD of Size: '
        '${_reUseBuffer.length}');
  } else {
    _reUseBuffer.reset;
  }
  return _reUseBuffer;
}
