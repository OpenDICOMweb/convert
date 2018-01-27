// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/bytes/buffer/write_buffer.dart';
import 'package:convert/src/dicom/base/writer/dcm_writer_base.dart';
import 'package:convert/src/dicom/base/writer/evr_writer.dart';
import 'package:convert/src/dicom/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

/// An encoder for Binary DICOM (application/dicom).
class EvrTagWriter extends EvrWriter<int> {
  @override
  WriteBuffer wb;
  @override
  final BDRootDataset rds;
  @override
  final EncodingParameters eParams;
  @override
  final int minLength;
  @override
  final bool reUseBD;
  @override
  Dataset cds;

  /// Creates a new [EvrTagWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  EvrTagWriter(this.rds, this.eParams, this.minLength, {this.reUseBD = false})
      : wb = getWriteBuffer(length: minLength, reUseBD: reUseBD),
        cds = rds;

  /// Creates a new [EvrTagWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  EvrTagWriter._(this.rds, this.eParams, this.minLength, this.reUseBD)
      : wb = getWriteBuffer(length: minLength, reUseBD: reUseBD),
        cds = rds;
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrLoggingTagWriter extends EvrTagWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  /// Creates a new [EvrLoggingTagWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  EvrLoggingTagWriter(
      RootDataset rds, EncodingParameters eParams, int minLength, this.inputOffsets,
      {bool reUseBD = false})
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super._(rds, eParams, minLength, reUseBD);
}
