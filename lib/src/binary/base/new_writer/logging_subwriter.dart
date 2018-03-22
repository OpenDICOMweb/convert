// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_writer/subwriter.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/parse_info.dart';

abstract class LoggingEvrSubWriter extends EvrSubWriter with LoggingSubWriter {
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  final ParseInfo pInfo;
  @override
  int elementCount;

  LoggingEvrSubWriter(
      EncodingParameters eParams, RootDataset rds, this.inputOffsets)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        elementCount = 0,
        super(eParams, rds);
}

abstract class LoggingIvrSubWriter extends IvrSubWriter with LoggingSubWriter {
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  final ParseInfo pInfo;
  @override
  int elementCount;

  LoggingIvrSubWriter(
      EncodingParameters eParams, RootDataset rds, this.inputOffsets)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        elementCount = 0,
        super(eParams, rds);
}

abstract class LoggingSubWriter {
  EncodingParameters get eParams;
  ElementOffsets get inputOffsets;
  ElementOffsets get outputOffsets;
  ParseInfo get pInfo;
  int get elementCount;
  RootDataset get rds;
  WriteBuffer get wb;
  SubWriter get subwriter;
  void writeOdwFmi();
  void writeExistingFmi();
  // **** End Interface

  Bytes writeRootDataset([int fmiEnd]) {
    log.debug('$_start writeRootDataset: fmiEnd($fmiEnd)');
    final bytes = subwriter.writeRootDataset();
    log..debug('$_end writeRootDataset: ${bytes.length} written');
    return bytes;
  }

  void writeItem(Item item) {
    log.debug('$_start writeItem: $item');
    subwriter.writeItem(item);
    log.debug('$_end writeItem: $item');
  }

  void writeShortElement(Element e) {
    log.debug(_startWrite(e, 'writeShort'));
    subwriter.writeShortElement(e);
    log.debug(_endWrite(e, 'writeShort'));
  }

  void writeLongElement(Element e) {
    log.debug(_startWrite(e, 'writeLong'));
    subwriter.writeLongElement(e);
    log.debug(_endWrite(e, 'writeLong'));
  }

  void writeMaybeUndefinedElement(Element e) {
    log.debug(_startWrite(e, 'writeMaybeUndefined'));
    subwriter..writeMaybeUndefinedLengthElement(e);
    log.debug(_endWrite(e, 'writeMaybeUndefined'));
  }

  void writeSequence(SQ sq) {
    log.debug(_startWrite(sq, 'writeSQ'));
    subwriter.writeSequence(sq, sq.vrIndex);
    log.debug(_endWrite(sq, 'writeSQ'));
  }

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to [wb], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  Bytes writeFmi() {
    if (!rds.hasFmi) {
      assert(pInfo.hadPrefix == false || !eParams.doAddMissingFMI);
      log.warn('Root Dataset does not have FMI: $rds');
      if (!eParams.allowMissingFMI || !eParams.doAddMissingFMI) {
        log.error('Dataset $rds is missing FMI elements');
        return kEmptyBytes;
      }
      if (eParams.doUpdateFMI) return subwriter.writeOdwFmi();
    }
    assert(rds.hasFmi);
    subwriter.writeExistingFmi(cleanPreamble: eParams.doCleanPreamble);
    return wb.subbytes(0, wb.wIndex);
  }

  // **** Internals

  WriteBuffer get _wb => wb;

  String get _index => '${_wb.index}'.padLeft(5, '0');

  String get _start => '>W@$_index';

  String get _end => '<W@$_index';

  String _startWrite(Element e, String id) => '$_start $id: $e';

  String _endWrite(Element e, String id) => '$_end $id: $e';
}
