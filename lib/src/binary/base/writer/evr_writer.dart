// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/padding_chars.dart';
import 'package:dcm_convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

//Urgent Jim: add to EvrULength at appropriate places

class EvrWriter extends DcmWriterBase {
  @override
  final bool isEvr = true;

  EvrWriter(RootDataset rds, EncodingParameters eParams, int minBDLength, bool reUseBD)
      : super(rds, eParams, minBDLength, reUseBD);

  @override
  void writeElement(Element e) {
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      wb.warn('** vrIndex changed to VR.kUN.index');
    }

    if (_isShortVR(vrIndex)) {
      writeShort(e);
    } else if (_isLongVR(vrIndex)) {
      writeLong(e);
    } else if (_isSequenceVR(vrIndex)) {
      writeSequence(e);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      writeMaybeUndefined(e);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }

/* Flush when fully working
    if (e.eStart != eStart) {
      log.error('** e.eStart(${e.eStart} != eStart($eStart)');
    }
    if (e.eEnd != wb.wIndex) {
      log.error('** e.eEnd(${e.eStart} != eEnd(${wb.wIndex})');
    }
*/
  }

  /// Write an EVR Element with a short Value Length field.
  void writeShort(Element e) {
    logStartWrite(wb.index, e, 'writeEvrShort');
    wb
      ..code(e.code)
      ..uint16(e.vrCode)
      ..uint16(e.vfLength);
    _writeValueField(e);
    logEndWrite(wb.index, e, 'writeEvrShort');
  }

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void writeLong(Element e) {
    logStartWrite(wb.index, e, 'writeEvrLong');
    assert(e.vfLengthField != kUndefinedLength);
    _writeEvrLongHeader(e, e.vfLength);
    _writeValueField(e);
    logEndWrite(wb.index, e, 'writeEvrLong');
  }

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void writeMaybeUndefined(Element e) {
//    logStartWrite(e, 'writeEvrMaybeUndefined');
    if (e.hadULength && !eParams.doConvertUndefinedLengths) {
      _writeLongEvrUndefinedLength(e);
    } else {
      writeLong(e);
    }
//    logEndWrite(wb.index, e, 'writeEvrMaybeUndefined');
  }

  /// Write a non-Sequence _undefined length_ Element.
  void _writeLongEvrUndefinedLength(Element e) {
    logStartWrite(wb.index, e, 'writeEvrUndefinedLength');
    assert(e.vfLengthField == kUndefinedLength);
    _writeEvrLongHeader(e, kUndefinedLength);
    if (e.code == kPixelData) {
      writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e);
    }
    wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
    logEndWrite(wb.index, e, 'writeEvrUndefinedLength');
  }

  /// Write a Sequence Element.
  void writeSequence(SQ e) => (e.hadULength && !eParams.doConvertUndefinedLengths)
      ? _writeEvrSQUndefinedLength(e)
      : _writeEvrSQDefinedLength(e);

  /// Write an EVR Sequence with _defined length_.
  void _writeEvrSQDefinedLength(SQ e) {
    logStartSQWrite(wb.index, e, 'writeEvrDefinedLengthSequence');
    final eStart = wb.wIndex;
    _writeEvrLongHeader(e, e.vfLength);
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfLength = (wb.index - eStart) - 12;
    wb.setUint32(vlfOffset, vfLength);
    logEndSQWrite(wb.index, e, 'writeEvrDefinedLengthSequence');
  }

  /// Write an EVR Sequence with _defined length_.
  void _writeEvrSQUndefinedLength(SQ e) {
    logStartSQWrite(wb.index, e, 'writeEvrUndefinedLengthSequence');
    _writeEvrLongHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
    logEndSQWrite(wb.index, e, 'writeEvrUndefinedLengthSequence');
  }

  void _writeEvrLongHeader(Element e, int vfLengthField) {
    wb
      ..code(e.code)
      ..uint16(e.vrCode)
      ..uint16(0)
      ..uint32(vfLengthField);
  }

  void _writeValueField(Element e) {
    final bytes = e.vfBytes;
    wb.bytes(bytes);
    if (bytes.length.isOdd) {
      final padChar = paddingChar(e.vrIndex);
      if (padChar.isNegative) {
        wb.error('Writing padding to a non-padded VR: $e');
        invalidVFLength(e.vfBytes.length, -1);
      }
      wb.uint8(e.padChar);
    }
  }

  // **** External interface for debugging and monitoring

  /// Write an EVR Element with a short Value Length field.
  void writeShortEvr(Element e) => writeShort(e);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void writeLongEvrDefinedLength(Element e) => writeLong(e);

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void writeEvrMaybeUndefined(Element e) => writeMaybeUndefined(e);

  /// Write a non-Sequence _undefined length_ Element.
  void writeLongEvrUndefinedLength(Element e) => _writeLongEvrUndefinedLength(e);

  /// Write a Sequence Element.
  void writeEvrSQ(SQ e) => writeSequence(e);

  /// Write an EVR Sequence with _defined length_.
  void writeEvrSQDefinedLength(SQ e) => _writeEvrSQDefinedLength(e);

  /// Write an EVR Sequence with _defined length_.
  void writeEvrSQUndefinedLength(SQ e) => _writeEvrSQUndefinedLength(e);

  // **** Write File Meta Information (FMI) ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  Uint8List writeFmi() {
    //  if (encoding.doUpdateFMI) return writeODWFMI();
    if (rds is! RootDataset) log.error('Not _rootDS');
    if (!rds.hasFmi) {
      final pInfo = rds.pInfo;
      assert(pInfo.hadPrefix == false || !eParams.doAddMissingFMI);
      log.warn('Root Dataset does not have FMI: $rds');
      if (!eParams.allowMissingFMI || !eParams.doAddMissingFMI) {
        log.error('Dataset $rds is missing FMI elements');
        return kEmptyUint8List;
      }
      if (eParams.doUpdateFMI) return writeOdwFmi(rds);
    }
    assert(rds.hasFmi);
    writeExistingFmi(rds, cleanPreamble: eParams.doCleanPreamble);
    return wb.toUint8List(0, wb.index);
  }

  Uint8List writeOdwFmi(RootDataset rootDS) {
    if (rootDS is! RootDataset) log.error('Not rds');
    writeCleanPrefix();
    //Urgent finish
    return wb.toUint8List(0, wb.index);
  }

  void writeExistingFmi(RootDataset rootDS, {bool cleanPreamble = true}) {
    writePrefix(rootDS, cleanPreamble: cleanPreamble);
    for (var e in rootDS.fmi) {
      if (e.code > 0x00030000) break;
      writeElement(e);
    }
  }

  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool writePrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    return (rds.preamble == null || eParams.doCleanPreamble)
        ? writeCleanPrefix()
        : writeExistingPrefix();
  }

  /// Writes a new Open DICOMweb FMI.
  bool writeCleanPrefix() {
    for (var i = 0; i < 128; i++) wb.uint8(0);
    wb.uint32(kDcmPrefix);
    return true;
  }

  /// Writes a new Open DICOMweb FMI.
  bool writeExistingPrefix() {
    assert(rds.preamble != null && !eParams.doCleanPreamble);
    final preamble = rds.preamble;
    for (var i = 0; i < 128; i++) wb.uint8(preamble.getUint8(i));
    wb.uint32(kDcmPrefix);
    return true;
  }

/* Flush if not used
  void writePrivateInformation(Uid uid, ByteData privateInfo) {
    wb.ascii(uid.asString);
  }
*/

  // **** Logging Interface ****
  void logStartWrite(int eStart, Element e, String name) {}

  void logEndWrite(int eStart, Element e, String name, {bool ok}) {}

  void logStartSQWrite(int eStart, Element e, String name) {}

  void logEndSQWrite(int eStart, Element e, String name, {bool ok}) {}
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;
