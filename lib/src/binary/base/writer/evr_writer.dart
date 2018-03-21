// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:convert/src/binary/base/padding_chars.dart';

//Urgent Jim: add to EvrULength at appropriate places

abstract class EvrWriter<V> extends DcmWriterBase<V> {
  static const int vfOffset = 12;

  @override
  final bool isEvr = true;

  void _writeEvrElement(Element e) {
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      log.warn('** vrIndex changed to VR.kUN.index');
    }
    if (_isShortVR(vrIndex)) {
      _writeShortEvr(e, vrIndex);
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
  void _writeShortEvr(Element e, int vrIndex) {
    assert(e != null);
    assert(e.vfLengthField != kUndefinedLength);
    assert(wb.index.isEven);
    assert(_isShortVR(e.vrIndex));
    final vfLength = e.vfLength + (e.vfLength.isOdd ? 1 : 0);
    assert(vfLength.isEven);
    assert(vfLength >= 0 && vfLength <= kMaxLongVF, 'length: $vfLength');
    wb
      ..writeCode(e.code)
      ..writeUint16(e.vrCode)
      ..writeUint16(vfLength);
    assert(wb.wIndex.isEven);
    _writeValueField(e);
  }

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void _writeLongDefinedLength(Element e, int vrIndex) {
    assert(e.vfLengthField != kUndefinedLength && wb.index.isEven);
    _writeLongHeader(e, e.vfLength);
    _writeValueField(e);
  }

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void _writeMaybeUndefinedLength(Element e, int vrIndex) {
    (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeLongUndefinedLength(e, vrIndex)
        : _writeLongDefinedLength(e, vrIndex);
  }

  /// Write a non-Sequence _undefined length_ Element.
  void _writeLongUndefinedLength(Element e, int vrIndex) {
    assert(_isMaybeUndefinedLengthVR(vrIndex) &&
        e.vfLengthField == kUndefinedLength &&
        wb.index.isEven);
    _writeLongHeader(e, kUndefinedLength);
    if (e.code == kPixelData) {
      writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e);
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
    _writeLongHeader(e, e.vfLength);
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfLength = (wb.wIndex - eStart) - vfOffset;
    assert(vfLength.isEven && wb.wIndex.isEven);
    wb.bytes.setUint32(vlfOffset, vfLength);
  }

  /// Write an EVR Sequence with _defined length_.
  // Note: A Sequence cannot have an _odd_ length.
  void _writeSQUndefinedLength(SQ e, int vrIndex) {
    assert(e is SQ && vrIndex == kSQIndex);
    assert(wb.index.isEven);
    _writeLongHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..writeUint32(kSequenceDelimitationItem32BitLE)..writeUint32(0);
    assert(wb.wIndex.isEven);
  }

  /// Write a Long Header with Value Length Field equal to [vfLengthField].
  bool _writeLongHeader(Element e, int vfLengthField) {
    assert(e != null && wb.wIndex.isEven);
    assert(_isNotShortVR(e.vrIndex), 'vrIndex: ${e.vrIndex}');
    final vfLength = e.vfLength;
    assert(vfLength != null);
    final isOddLength = vfLength.isOdd;
    final length = vfLength + (isOddLength ? 1 : 0);
    assert(length.isEven);
    assert(length >= 0 && length < kUndefinedLength, 'length: $length');
    wb
      ..writeCode(e.code)
      ..writeUint16(e.vrCode)
      ..writeUint16(0)
      ..writeUint32(vfLengthField);
    assert(wb.index.isEven);
    return isOddLength;
  }

  void _writeValueField(Element e) {
    assert(wb.wIndex.isEven);
    wb.write(e.vfBytes);
    if (e.vfLength.isOdd) _writePaddingChar(e);
    assert(wb.wIndex.isEven);
  }

  void _writePaddingChar(Element e) {
    assert(wb.wIndex.isOdd, 'vfLength: ${e.vfLength} - $e');
    final padChar = paddingChar(e.vrIndex);
    if (padChar.isNegative) {
      log.error('Padding a non-padded Element: $e');
      return invalidVFLength(e.vfBytes.length, -1);
    }
    wb.writeUint8(padChar);
    assert(wb.wIndex.isEven);
  }

  // **** External interface for debugging and monitoring

  @override
  void writeElement(Element e) => _writeEvrElement(e);

  /// Write an EVR Element with a short Value Length field.
  void writeShort(Element e, int vrIndex) => writeShort(e, vrIndex);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void writeLongDefinedLength(Element e, int vrIndex) =>
      _writeLongDefinedLength(e, vrIndex);

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void writeMaybeUndefinedLength(Element e, int vrIndex) =>
      _writeMaybeUndefinedLength(e, vrIndex);

  /// Write a non-Sequence _undefined length_ Element.
  void writeLongUndefinedLength(Element e, int vrIndex) =>
      _writeLongUndefinedLength(e, vrIndex);

  /// Write a Sequence Element.
  void writeSequence(SQ e, int vrIndex) => _writeSequence(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQDefinedLength(SQ e, int vrIndex) =>
      _writeSQDefinedLength(e, vrIndex);

  /// Write an EVR Sequence with _defined length_.
  void writeSQUndefinedLength(SQ e, int vrIndex) =>
      _writeSQUndefinedLength(e, vrIndex);

  // **** Write File Meta Information (FMI) ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  Bytes writeFmi() {
    //  if (encoding.doUpdateFMI) return writeODWFMI();
    if (rds is! RootDataset) log.error('Not _rootDS');
    if (!rds.hasFmi) {
      final pInfo = rds.pInfo;
      assert(pInfo.hadPrefix == false || !eParams.doAddMissingFMI);
      log.warn('Root Dataset does not have FMI: $rds');
      if (!eParams.allowMissingFMI || !eParams.doAddMissingFMI) {
        log.error('Dataset $rds is missing FMI elements');
        return kEmptyBytes;
      }
      if (eParams.doUpdateFMI) return writeOdwFmi(rds);
    }
    assert(rds.hasFmi);
    writeExistingFmi(rds, cleanPreamble: eParams.doCleanPreamble);
    return wb.subbytes(0, wb.wIndex);
  }

  Bytes writeOdwFmi(RootDataset rootDS) {
    if (rootDS is! RootDataset) log.error('Not rds');
    writeCleanPrefix();
    //Urgent finish
    return wb.subbytes(0, wb.wIndex);
  }

  void writeExistingFmi(RootDataset rootDS, {bool cleanPreamble = true}) {
    writePrefix(rootDS, cleanPreamble: cleanPreamble);
    for (var e in rootDS.fmi.elements) {
      if (e.code > 0x00030000) break;
      writeElement(e);
    }
  }

  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool writePrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    return (rds.prefix == kEmptyBytes || eParams.doCleanPreamble)
        ? writeCleanPrefix()
        : writeExistingPreambleAndPrefix();
  }

  /// Writes a new Open DICOMweb FMI.
  bool writeCleanPrefix() => wb.writeZeros(128);

/* Flush when working
  /// Writes a new Open DICOMweb FMI.
  bool writeCleanPrefix() {
    for (var i = 0; i < 128; i++) wb.writeUint8(0);
    wb.writeUint32(kDcmPrefix);
    return true;
  }
*/

  /// Writes a new Open DICOMweb FMI.
  bool writeExistingPreambleAndPrefix() {
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
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin &&
    vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isLongDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isNotShortVR(int vrIndex) => !_isShortVR(vrIndex);
