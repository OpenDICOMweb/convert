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

    if (_isEvrShortLengthVR(vrIndex)) {
      _writeShortEvr(e);
    } else if (_isEvrLongLengthVR(vrIndex)) {
      _writeLongEvrDefinedLength(e);
    } else if (_isSequenceVR(vrIndex)) {
      _writeEvrSQ(e);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeEvrMaybeUndefined(e);
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
  void _writeShortEvr(Element e) {
    wb
      ..code(e.code)
      ..uint16(e.vrCode)
      ..uint16(e.vfLength);
    _writeValueField(e);
  }

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void _writeLongEvrDefinedLength(Element e) {
    assert(e.vfLengthField != kUndefinedLength);
    _writeEvrLongHeader(e, e.vfLength);
    _writeValueField(e);
  }

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void _writeEvrMaybeUndefined(Element e) =>
      (e.hadULength && !eParams.doConvertUndefinedLengths)
          ? _writeLongEvrUndefinedLength(e)
          : _writeLongEvrDefinedLength(e);

  /// Write a non-Sequence _undefined length_ Element.
  void _writeLongEvrUndefinedLength(Element e) {
    assert(e.vfLengthField == kUndefinedLength);
    _writeEvrLongHeader(e, kUndefinedLength);
    if (e.code == kPixelData) {
      writeEncapsulatedPixelData(e);
    } else {
      _writeValueField(e);
    }
    wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
  }

  /// Write a Sequence Element.
  void _writeEvrSQ(SQ e) => (e.hadULength && !eParams.doConvertUndefinedLengths)
      ? _writeEvrSQUndefinedLength(e)
      : _writeEvrSQDefinedLength(e);

  /// Write an EVR Sequence with _defined length_.
  void _writeEvrSQDefinedLength(SQ e) {
    final eStart = wb.wIndex;
    _writeEvrLongHeader(e, e.vfLength);
    final vlfOffset = wb.wIndex - 4;
    writeItems(e.items);
    final vfLength = (wb.index - eStart) - 12;
    wb.setUint32(vlfOffset, vfLength);
  }

  /// Write an EVR Sequence with _defined length_.
  void _writeEvrSQUndefinedLength(SQ e) {
    _writeEvrLongHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
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
      log.warn('**** Odd length: ${bytes.length}');
      if (e.padChar.isNegative) return invalidVFLength(e.vfBytes.length, -1);
      wb.uint8(e.padChar);
    }
  }

  // **** External interface for debugging and monitoring

  /// Write an EVR Element with a short Value Length field.
  void writeShortEvr(Element e) => _writeShortEvr(e);

  /// Write a non-Sequence EVR Element with a long Value Length field
  /// and a _defined length_.
  void writeLongEvrDefinedLength(Element e) => _writeLongEvrDefinedLength(e);

  /// Write a non-Sequence Element (OB, OW, UN) that may have an undefined length
  void writeEvrMaybeUndefined(Element e) => _writeEvrMaybeUndefined(e);

  /// Write a non-Sequence _undefined length_ Element.
  void writeLongEvrUndefinedLength(Element e) => _writeLongEvrUndefinedLength(e);

  /// Write a Sequence Element.
  void writeEvrSQ(SQ e) => _writeEvrSQ(e);

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
    for (var e in rootDS.elements) {
      if (e.code > 0x00030000) break;
      writeElement(e);
    }
  }

  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool writePrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    final pInfo = rds.pInfo;
    return (pInfo.preambleAllZeros || eParams.doCleanPreamble)
        ? writeCleanPrefix()
        : writeExistingPrefix(pInfo);
  }

  /// Writes a new Open DICOMweb FMI.
  bool writeCleanPrefix() {
    for (var i = 0; i < 128; i++) wb.uint8(0);
    wb.uint32(kDcmPrefix);
    return true;
  }

  /// Writes a new Open DICOMweb FMI.
  bool writeExistingPrefix(ParseInfo pInfo) {
    assert(pInfo.preamble != null && !eParams.doCleanPreamble);
    for (var i = 0; i < 128; i++) wb.uint8(pInfo.preamble[i]);
    wb.uint32(kDcmPrefix);
    return true;
  }

  void writePrivateInformation(Uid uid, ByteData privateInfo) {
    wb.ascii(uid.asString);
  }
}

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongLengthVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortLengthVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;
