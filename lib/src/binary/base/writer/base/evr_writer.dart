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

import 'package:dcm_convert/src/binary/base/writer/base/dcm_writer_base.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

class EvrWriter extends DcmWriterBase {
  @override
  final bool isEvr = true;

  EvrWriter(RootDataset rds,
      {String path,
      TransferSyntax outputTS,
      int minLength,
      bool reUseBD = true,
      EncodingParameters eParams = EncodingParameters.kNoChange,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets})
      : super(rds,
            path: path,
            eParams: eParams,
            outputTS: outputTS,
            minLength: minLength,
            reUseBD: reUseBD,
            elementOffsetsEnabled: elementOffsetsEnabled,
            inputOffsets: inputOffsets);

  @override
  Uint8List writeRootDataset(RootDataset rds) {
    final dsStart = wb.index;
    log.debug('${wb.wbb} writeEvrRootDataset $rds :${wb.remaining}');
    // ignore: prefer_forEach
    for (var e in rds.elements) {
      writeElement(e);
    }

    log.debug('${wb.wee} writeEvrRootDataset  :${wb.remaining}');
    return wb.toUint8List(dsStart, wb.index - dsStart);
  }

  @override
  void writeElement(Element e, {ElementOffsets inputOffsets}) {
    elementCount++;
    final eStart = wb.wIndex;
    var vrIndex = e.vrIndex;

    if (_isSpecialVR(vrIndex)) {
      // This should not happen
      vrIndex = VR.kUN.index;
      wb.warn('** vrIndex changed to VR.kUN.index');
    }

    log.debug('${wb.wbb} #$elementCount writeEvrElement $e :${wb.remaining}', 1);
    if (_isEvrShortLengthVR(vrIndex)) {
      _writeShortEvr(e);
    } else if (_isEvrLongLengthVR(vrIndex)) {
      _writeLongEvr(e);
    } else if (_isSequenceVR(vrIndex)) {
      _writeEvrSQ(e);
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      _writeEvrMaybeUndefined(e);
    } else {
      throw new ArgumentError('Invalid VR: $e');
    }

    if (e.eStart != eStart) {
      log.error('** e.eStart(${e.eStart} != eStart($eStart)');
    }
    if (e.eEnd != wb.wIndex) {
      log.error('** e.eEnd(${e.eStart} != eEnd(${wb.wIndex})');
    }

    pInfo.nElements++;
    doEndOfElementStats(eStart, wb.wIndex, e);
    log.debug('${wb.wee} #$elementCount writeEvrElement ${e.dcm} ${e.keyword}', -2);
  }

  void _writeShortEvr(Element e) {
    log.debug('${wb.wbb} writeShortEvr $e :${wb.remaining}', 1);
    wb
      ..code(e.code)
      ..uint16(e.vrCode)
      ..uint16(e.vfLength);
    _writeValueField(e);
    pInfo.nShortElements++;
  }

  void _writeLongEvr(Element e) {
    log.debug('${wb.wbb} writeLongEvr $e :${wb.remaining}', 1);
    _reallyEvrWriteDefinedLength(e);
  }

  void _writeEvrMaybeUndefined(Element e) {
    log.debug('${wb.wbb} writeEvrMaybeUndefined $e :${wb.remaining}', 1);
    pInfo.nMaybeUndefinedElements++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _reallyEvrWriteUndefinedLength(e)
        : _reallyEvrWriteDefinedLength(e);
  }

  void _writeEvrSQ(SQ e) {
    pInfo.nSequences++;
    if (e.isPrivate) pInfo.nPrivateSequences++;
    return (e.hadULength && !eParams.doConvertUndefinedLengths)
        ? _writeEvrSQUndefinedLength(e)
        : _writeEvrSQDefinedLength(e);
  }

  void _writeEvrSQDefinedLength(SQ e) {
    log.debug('${wb.wbb} writeEvrSQDefinedLength $e :${wb.remaining}', 1);
    pInfo.nDefinedLengthSequences++;
    final index = outputOffsets.reserveSlot;
    final eStart = wb.wIndex;
    final vlf = e.vfLength;
    final vlfOffset = _writeEvrLongHeader(e, e.vfLength);
    writeItems(e.items);
    final eEnd = wb.wIndex;
    assert(e.vfLength + 12 == e.eEnd - e.eStart, '$vlf, $eEnd - $eStart');
    assert(vlf + 12 == (eEnd - eStart), '$vlf, $eEnd - $eStart');
    final vfLength = (eEnd - eStart) - 12;
    // print('$eStart - $eEnd vfLength: $vlf, $vfLength');
    wb.setUint32(vlfOffset, vfLength);
    // print('evrDef: $eStart $eEnd, $e');
    outputOffsets.insertAt(index, eStart, eEnd, e);
  }

  void _writeEvrSQUndefinedLength(SQ e) {
    final index = outputOffsets.reserveSlot;
    final eStart = wb.wIndex;
    log.debug('${wb.wbb} writeEvrSQUndefinedLength $e :${wb.remaining}', 1);
    pInfo.nUndefinedLengthSequences++;
    _writeEvrLongHeader(e, kUndefinedLength);
    writeItems(e.items);
    wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
    final eEnd = wb.wIndex;
    // print('evrDef: $eStart $eEnd, $e');
    outputOffsets.insertAt(index, eStart, eEnd, e);
  }

  void _reallyEvrWriteDefinedLength(Element e) {
    log.debug('${wb.wmm} writeEvrUndefined $e :${wb.remaining}');
    if (e.code == kPixelData) {}
    _writeEvrLongHeader(e, e.vfLength);
    _writeValueField(e);
    pInfo.nLongElements++;
  }

  void _reallyEvrWriteUndefinedLength(Element e) {
    log.debug('${wb.wmm} writeEvrUndefined $e :${wb.remaining}');
    if (e.code == kPixelData) {
      updatePInfoPixelData(e);
      _writeEncapsulatedPixelData(e);
    } else {
      _writeEvrLongHeader(e, kUndefinedLength);
      _writeValueField(e);
      wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
    }
    pInfo.nUndefinedLengthElements++;
  }

  int _writeEvrLongHeader(Element e, int vfLengthField) {
    wb
      ..code(e.code)
      ..uint16(e.vrCode)
      ..uint16(0)
      ..uint32(vfLengthField);
    return wb.wIndex - 4;
  }

  void _writeEncapsulatedPixelData(Element e) {
    updatePInfoPixelData(e);
    _writeEvrLongHeader(e, e.vfLengthField);
    if (e.vfLengthField == kUndefinedLength) {
      for (final bytes in e.fragments.fragments) {
        wb
          ..uint32(kItem32BitLE)
          ..uint32(bytes.lengthInBytes)
          ..bytes(bytes);
      }
      wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
      pInfo.pixelDataEnd = wb.wIndex;
    }
  }

  void _writeValueField(Element e) {
    final bytes = e.vfBytes;
    // print('bytes.length: ${bytes.lengthInBytes}');
    wb.bytes(bytes);
    if (bytes.length.isOdd) {
      log.warn('**** Odd length: ${bytes.length}');
      if (e.padChar.isNegative) return invalidVFLength(e.vfBytes.length, -1);
      wb.uint8(e.padChar);
    }
  }

  // **** Write File Meta Information (FMI) ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  Uint8List writeFmi() {
    //  if (encoding.doUpdateFMI) return writeODWFMI();
    if (rds is! RootDataset) log.error('Not _rootDS');
    if (!rds.hasFmi) {
      final pInfo = rds.parseInfo;
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

//TODO: redoc
  /// Writes a DICOM Preamble and Prefix (see PS3.10) as the
  /// beginning of the encoding.
  bool writePrefix(RootDataset rds, {bool cleanPreamble = true}) {
    if (rds is! RootDataset) log.error('Not rds');
    final pInfo = rds.parseInfo;
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
