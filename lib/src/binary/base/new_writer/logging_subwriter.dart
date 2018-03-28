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
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  LoggingEvrSubWriter(RootDataset rds, EncodingParameters eParams)
      : offsets = new ElementOffsets(),
        pInfo = new ParseInfo(rds),
        super(rds, eParams);

  @override
  EvrSubWriter get subWriter;
}

abstract class LoggingIvrSubWriter extends IvrSubWriter with LoggingSubWriter {
  @override
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  LoggingIvrSubWriter(RootDataset rds, EncodingParameters eParams)
      : offsets = new ElementOffsets(),
        pInfo = new ParseInfo(rds),
        super(rds, eParams);

  @override
  IvrSubWriter get subWriter;
}

abstract class LoggingSubWriter {
  SubWriter get subWriter;
  ElementOffsets get offsets;
  ParseInfo get pInfo;
  RootDataset get rds => subWriter.rds;
  EncodingParameters get eParams => subWriter.eParams;
  WriteBuffer get wb => subWriter.wb;
  TransferSyntax get outputTS => subWriter.outputTS;
  bool get doLogging => subWriter.doLogging;

  void writeOdwFmi();
  void writeExistingFmi();
  // **** End Interface

  Bytes writeRootDataset([int fmiEnd]) {
    log.debug('$_start writeRootDataset: fmiEnd($fmiEnd)');
    final bytes = subWriter.writeRootDataset();
    log..debug('$_end writeRootDataset: ${bytes.length} written');
    return bytes;
  }

  void writeItem(Item item) {
    log.debug('$_start writeItem: $item');
    subWriter.writeItem(item);
    log.debug('$_end writeItem: $item');
  }

  void writeShortElement(Element e) {
    log.debug(_startWrite(e, 'writeShort'));
    subWriter.writeShortElement(e);
    log.debug(_endWrite(e, 'writeShort'));
  }

  void writeLongElement(Element e) {
    log.debug(_startWrite(e, 'writeLong'));
    subWriter.writeLongElement(e);
    log.debug(_endWrite(e, 'writeLong'));
  }

  void writeMaybeUndefinedElement(Element e) {
    log.debug(_startWrite(e, 'writeMaybeUndefined'));
    subWriter..writeMaybeUndefinedLengthElement(e);
    log.debug(_endWrite(e, 'writeMaybeUndefined'));
  }

  void writeSequence(SQ sq) {
    log.debug(_startWrite(sq, 'writeSQ'));
    subWriter.writeSequence(sq, sq.vrIndex);
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
      if (eParams.doUpdateFMI) return subWriter.writeOdwFmi();
    }
    assert(rds.hasFmi);
    subWriter.writeExistingFmi(cleanPreamble: eParams.doCleanPreamble);
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
