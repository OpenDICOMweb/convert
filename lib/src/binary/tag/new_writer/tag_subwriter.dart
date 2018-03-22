// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_writer/subwriter.dart';
import 'package:convert/src/binary/base/new_writer/logging_subwriter.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

int minLength = 256;
bool reUseWriteBuffer = true;

/// An encoder for Binary DICOM (application/dicom).
class TagEvrSubWriter extends EvrSubWriter {
  @override
  final BDRootDataset rds;
  @override
  WriteBuffer wb;

  /// Creates a new [TagEvrSubWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  TagEvrSubWriter(EncodingParameters eParams, RootDataset rds)
      : rds = rds,
        wb = getWriteBuffer(length: minLength, reUseBD: reUseWriteBuffer),
        super(eParams, rds);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingTagEvrSubWriter extends LoggingEvrSubWriter {
  @override
  final RootDataset rds;
  @override
  WriteBuffer wb;

  /// Creates a new [LoggingTagEvrSubWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  LoggingTagEvrSubWriter(
      EncodingParameters eParams, RootDataset rds, ElementOffsets inputOffsets)
      : rds = rds,
        wb = getWriteBuffer(length: minLength, reUseBD: reUseWriteBuffer),
        super(eParams, rds, inputOffsets);

  @override
  SubWriter get subwriter => this;
}

/// An encoder for Binary DICOM (application/dicom).
class TagIvrSubWriter extends IvrSubWriter {
  @override
  final RootDataset rds;
  @override
  WriteBuffer wb;

  /// Creates a new [TagIvrSubWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  TagIvrSubWriter(EncodingParameters eParams, RootDataset rds)
      : rds = rds,
        wb = getWriteBuffer(length: minLength, reUseBD: reUseWriteBuffer),
        super(eParams, rds);

  TagIvrSubWriter.from(TagEvrSubWriter writer)
      : rds = writer.rds,
        wb = writer.wb,
        super(writer.eParams, writer.rds);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingTagIvrSubWriter extends LoggingIvrSubWriter {
  @override
  final RootDataset rds;
  @override
  WriteBuffer wb;

  /// Creates a new [LoggingTagIvrSubWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  LoggingTagIvrSubWriter.from(LoggingTagEvrSubWriter subwriter)
      : rds = subwriter.rds,
        wb = subwriter.wb,
        super(subwriter.eParams, subwriter.rds, subwriter.inputOffsets);

  @override
  SubWriter get subwriter => this;
}
