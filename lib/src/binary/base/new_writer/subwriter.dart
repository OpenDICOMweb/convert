// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/padding_chars.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

//Urgent Jim: add to EvrULength at appropriate places

const int vfOffset = 12;

typedef void ElementSubWriter(Element e);

abstract class EvrSubWriter extends SubWriter {
  @override
  final bool isEvr = true;
  @override
  final EncodingParameters eParams;
  @override
  Dataset cds;

  EvrSubWriter(this.eParams, this.cds);

  /// Write an EVR [Element].
  @override
  void _writeElement(Element e, [int vrIndex]) {
    assert(e != null);
    print(e);
    vrIndex ??= e.vrIndex;

    assert(!_isSpecialVR(vrIndex), 'Invalid VR: $vrIndex');

/* TODO: remove when fully debugged
    if (_isSpecialVR(vrIndex)) {
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }
*/

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
  }

  /// Write an EVR Element with a short Value Length field.
  @override
  void _writeShort(Element e, int vrIndex) {
    assert(e.vfLengthField != kUndefinedLength && wb.index.isEven);
    final vfLength = e.vfLength + (e.vfLength.isOdd ? 1 : 0);
    assert(vfLength.isEven);
    assert(vfLength >= 0 && vfLength <= kMaxShortVF, 'length: $vfLength');
    __writeShortHeader(e, vrIndex, vfLength);
    _writeValueField(e, vrIndex);
  }

  void __writeShortHeader(Element e, int vrIndex, int vfLength) {
    assert(_isEvrShortVR(vrIndex));
    wb
      ..writeCode(e.code)
      ..writeUint16(e.vrCode)
      ..writeUint16(vfLength);
  }

  /// Write a Long EVR [Element], i.e. with 32-bit Value Field Length field.
  @override
  void __writeLongHeader(Element e, int vfLengthField, int vrIndex) {
    assert(_isEvrLongVR(vrIndex));
    wb
      ..writeCode(e.code)
      ..writeUint16(e.vrCode)
      ..writeUint16(0)
      ..writeUint32(vfLengthField);
  }

  bool _isEvrLongVR(int vrIndex) =>
      vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;
}

/// A class that writes IVR Elements.
abstract class IvrSubWriter extends SubWriter {
  @override
  final bool isEvr = false;
  @override
  final EncodingParameters eParams;
  @override
  Dataset cds;

  IvrSubWriter(this.eParams, this.cds);

  /// Write an IVR [Element].
  @override
  void _writeElement(Element e, [int vrIndex]) {
    assert(e != null);
    print(e);

    // Since VR is determinded by Tag, it might be a special VR.
    vrIndex ??= e.vrIndex;
    assert(!_isSpecialVR(vrIndex), 'Invalid VR: $vrIndex');

/* TODO: remove when fully debugged
    if (_isSpecialVR(vrIndex)) {
      vrIndex = kUNIndex;
      log.warn('** vrIndex changed to kUNIndex');
    }
*/
    if (_isIvrDefinedLengthVR(vrIndex)) {
      _writeLongDefinedLength(e, vrIndex);
    } else if (_isSequenceVR(vrIndex)) {
      _writeSequence(e, vrIndex);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeMaybeUndefinedLength(e, vrIndex);
    } else {
      throw new ArgumentError('Invalid VR($vrIndex): $e');
    }
  }

  bool _isIvrDefinedLengthVR(int vrIndex) =>
      vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

  /// Write a Long IVR [Element] header,
  /// i.e. with 32-bit Value Field Length field.
  ///
  /// _Note_: all IVR Headers have 32-bit Value Field Length field.
  @override
  void __writeLongHeader(Element e, int _, int vfLengthField) {
    assert(vfLengthField >= 0 && vfLengthField <= kMaxLongVF);
    wb
      ..writeCode(e.code)
      ..writeUint32(vfLengthField);
  }
}

abstract class SubWriter {
  bool get isEvr;
  WriteBuffer get wb;
  RootDataset get rds;
  Dataset get cds;
  set cds(Dataset ds);

  EncodingParameters get eParams;

  void _writeElement(Element e, [int vrIndex]);

  void _writeShort(Element e, int vrIndex) => unsupportedError();

  void __writeLongHeader(Element e, int vfLengthField, int vrIndex);

  // **** End of Interface

  /// Return's the current position of the write index ([wIndex]).
  int get wIndex => wb.wIndex;

  TransferSyntax get ts => rds.transferSyntax;

  /// The current [length] in bytes of this [SubWriter].
  int get lengthInBytes => wb.wIndex;

  /// The current [length] in bytes of this [SubWriter].
  int get length => lengthInBytes;

  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  bool get isFmiWritten => _isFmiWritten;
  // ignore: prefer_final_fields
  bool _isFmiWritten = false;
  set isFmiWritten(bool v) => _isFmiWritten ??= true;

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Bytes _writeRootDataset() {
    _writeDataset(rds);
    return wb.subbytes(0, wb.wIndex);
  }

  void _writeDataset(Dataset ds) {
    // ignore: prefer_forEach
    for (var e in ds.elements) {
      _writeElement(e);
    }
  }

  /// Write all [Item]s in [items].
  void _writeItems(List<Item> items) {
    for (var item in items) {
      final parentDS = cds;
      cds = item;
      writeItem(item);
      cds = parentDS;
    }
  }

  /// Write one [Item].
  void _writeItem(Item item) =>
      (item.hasULength && !eParams.doConvertUndefinedLengths)
          ? _writeUndefinedLengthItem(item)
          : _writeDefinedLengthItem(item);

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthItem(Item item) {
    wb..writeUint32(kItem32BitLE)..writeUint32(item.vfLength);
    _writeDataset(item);
  }

  void _writeUndefinedLengthItem(Item item) {
    wb..writeUint32(kItem32BitLE)..writeUint32(kUndefinedLength);
    _writeDataset(item);
    wb..writeUint32(kItemDelimitationItem32BitLE)..writeUint32(0);
  }

  void _writeEncapsulatedPixelData(IntBase e) {
    assert(e.vfLengthField == kUndefinedLength);
    for (final fragment in e.fragments.fragments) {
      wb
        ..writeUint32(kItem32BitLE)
        ..writeUint32(fragment.lengthInBytes)
        ..writeUint8List(fragment);

      // If odd length write padding byte
      if (fragment.length.isOdd) {
        log.warn('Odd length(${fragment.lengthInBytes}) fragment');
        wb.writeUint8(0);
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
      vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVREvrLongIndexMax;

  bool _isEvrShortVR(int vrIndex) =>
      vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

  bool _isNotShortVR(int vrIndex) => !_isEvrShortVR(vrIndex);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void _writeLongDefinedLength(Element e, [int vrIndex]) {
    assert(e.vfLengthField != kUndefinedLength && wb.index.isEven);
    _writeLongHeader(e, vrIndex, e.vfLength);
    _writeValueField(e, vrIndex);
  }

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void _writeMaybeUndefinedLength(Element e, [int vrIndex]) {
    (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeLongUndefinedLength(e, vrIndex)
        : _writeLongDefinedLength(e, vrIndex);
  }

  /// Write a non-Sequence _undefined length_ Element.
  void _writeLongUndefinedLength(Element e, [int vrIndex]) {
    assert(_isMaybeUndefinedLengthVR(vrIndex) &&
        e.vfLengthField == kUndefinedLength &&
        wb.index.isEven);
    _writeLongHeader(e, vrIndex, kUndefinedLength);
    if (e.code == kPixelData) {
      _writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e, vrIndex);
    }
    wb..writeUint32(kSequenceDelimitationItem32BitLE)..writeUint32(0);
    assert(wb.wIndex.isEven);
  }

  /// Write a Sequence Element.
  void _writeSequence(SQ e, int vrIndex) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeSQUndefinedLength(e, vrIndex)
          : _writeSQDefinedLength(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQDefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && vrIndex == kSQIndex);
    final eStart = wb.wIndex;
    assert(eStart.isEven);
    _writeLongHeader(e, vrIndex, e.vfLength);
    // This if the offset where the vfLengthField will be written
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfOffset = isEvr ? 12 : 8;
    final vfLength = (wb.wIndex - eStart) - vfOffset;
    assert(vfLength.isEven && wb.wIndex.isEven);
    // Now that vfLength is known write it at vflOffset.
    wb.bytes.setUint32(vlfOffset, vfLength);
  }

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQUndefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && vrIndex == kSQIndex);
    assert(wb.index.isEven);
    _writeLongHeader(e, vrIndex, kUndefinedLength);
    writeItems(e.items);
    wb..writeUint32(kSequenceDelimitationItem32BitLE)..writeUint32(0);
    assert(wb.wIndex.isEven);
  }

  /// Write a Long Header with Value Length Field equal to [vfLengthField].
  bool _writeLongHeader(Element e, int vrIndex, int vfLengthField) {
    assert(e != null && wb.wIndex.isEven);
    assert(_isNotShortVR(vrIndex), 'vrIndex: $vrIndex');
    final vfLength = e.vfLength;
    assert(vfLength != null);
    final isOddLength = vfLength.isOdd;
    final length = vfLength + (isOddLength ? 1 : 0);
    assert(length.isEven);
    assert(length >= 0 && length < kUndefinedLength, 'length: $length');
    __writeLongHeader(e, vrIndex, vfLengthField);
    assert(wb.index.isEven);
    return isOddLength;
  }

  void _writeValueField(Element e, int vrIndex) {
    assert(wb.wIndex.isEven);
    wb.write(e.vfBytes);
    if (e.vfLength.isOdd) _writePaddingChar(e, vrIndex);
    assert(wb.wIndex.isEven);
  }

  void _writePaddingChar(Element e, int vrIndex) {
    assert(wb.wIndex.isOdd, 'vfLength: ${e.vfLength} - $e');
    final padChar = paddingChar(vrIndex);
    if (padChar.isNegative) {
      log.error('Padding a non-padded Element: $e');
      return invalidVFLength(e.vfBytes.length, -1);
    }
    wb.writeUint8(padChar);
    assert(wb.wIndex.isEven);
  }

  // **** Write File Meta Information (FMI) ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  Bytes _writeFmi() {
    if (!rds.hasFmi) {
      if (!eParams.allowMissingFMI || !eParams.doAddMissingFMI) {
        log.error('Dataset $rds is missing FMI elements');
        return kEmptyBytes;
      }
      if (eParams.doUpdateFMI) return _writeOdwFmi();
    }
    assert(rds.hasFmi);
    _writeExistingFmi(cleanPreamble: eParams.doCleanPreamble);
    return wb.subbytes(0, wb.wIndex);
  }

  Bytes _writeOdwFmi() {
    _writeCleanPrefix();
    //Urgent finish
    return wb.subbytes(0, wb.wIndex);
  }

  void _writeExistingFmi({bool cleanPreamble = true}) {
    _writePrefix(rds, cleanPreamble: cleanPreamble);
    for (var e in rds.fmi.elements) {
      if (e.code > 0x00030000) break;
      _writeElement(e);
    }
  }

  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool _writePrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    return (rds.prefix == kEmptyBytes || eParams.doCleanPreamble)
        ? _writeCleanPrefix()
        : _writeExistingPreambleAndPrefix();
  }

  /// Writes a new Open DICOMweb FMI.
  bool _writeCleanPrefix() => wb.writeZeros(128);

/* Flush when working
  /// Writes a new Open DICOMweb FMI.
  bool writeCleanPrefix() {
    for (var i = 0; i < 128; i++) wb.writeUint8(0);
    wb.writeUint32(kDcmPrefix);
    return true;
  }
*/

  /// Writes a new Open DICOMweb FMI.
  bool _writeExistingPreambleAndPrefix() {
    assert(rds.prefix != kEmptyBytes && !eParams.doCleanPreamble);
    final preamble = rds.preamble;
    for (var i = 0; i < 128; i++) wb.writeUint8(preamble.getUint8(i));
    // final prefix = rds.prefix;
    //  for (var i = 0; i < 4; i++) wb.writeUint8(prefix.getUint8(i));
    wb.writeUint32(kDcmPrefix);
    return true;
  }

/* Flush if not used
  void writePrivateInformation(Uid uid, Bytes privateInfo) {
    wb.ascii(uid.asString);
  }
*/

  // **** External interface for debugging and monitoring

// Urgent: decide on best way to handle this
//  void writeElement(Element e) => _writeElement(e);

  Bytes writeRootDataset() => _writeRootDataset();
  Bytes writeFmi() => _writeFmi();
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
          ? system.defaultTransferSyntax
          : rds.transferSyntax;
    } else {
      return outputTS;
    }
  }
*/

}

/// The default [Bytes] buffer length, if none is provided.
const int kDefaultWriteBufferLength = k1MB; //200 * k1MB;

/// A reusable  [WriteBuffer] is stored here.
WriteBuffer _reUseBuffer;

WriteBuffer getWriteBuffer({int length, bool reUseBD = false}) {
  length ??= kDefaultWriteBufferLength;

  if (!reUseBD || _reUseBuffer == null)
    return _reUseBuffer = new WriteBuffer(length);

  if (length > _reUseBuffer.lengthInBytes) {
    _reUseBuffer = new WriteBuffer(length + 1024);
    log.warn(
        '**** DcmSubWriterBase creating new Reuse BD of Size: ${_reUseBuffer
        .lengthInBytes}');
  }
  _reUseBuffer.reset;
  return _reUseBuffer;
}
