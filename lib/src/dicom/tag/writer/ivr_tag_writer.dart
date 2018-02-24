// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/writer/dcm_writer_base.dart';
import 'package:convert/src/dicom/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/dicom/base/writer/ivr_writer.dart';
import 'package:convert/src/dicom/base/writer/log_write_mixin_base.dart.old';
import 'package:convert/src/dicom/byte_data/writer/evr_bd_writer.dart';


// ignore_for_file: avoid_positional_boolean_parameters

/// An encoder for Binary DICOM (application/dicom).
class IvrTagWriter extends IvrWriter<int> with LogWriteMixinBase {
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

  /// Creates a new [IvrTagWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrTagWriter(this.rds, this.eParams, this.minLength, {this.reUseBD = false})
      : wb = getWriteBuffer(length: minLength, reUseBD: reUseBD),
        cds = rds;

  IvrTagWriter._(this.rds, this.eParams, this.minLength, this.reUseBD)
      : wb = getWriteBuffer(length: minLength, reUseBD: reUseBD),
        cds = rds;

  IvrTagWriter.from(EvrBDWriter writer)
      : wb = writer.wb,
        rds = writer.rds,
        eParams = writer.eParams,
        minLength = writer.minLength,
        reUseBD = writer.reUseBD,
        cds = writer.cds;
}

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrLoggingTagWriter extends IvrTagWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  /// Creates a new [IvrLoggingTagWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrLoggingTagWriter(RootDataset rds, EncodingParameters eParams, int minLength,
      bool reUseBD, this.inputOffsets)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super._(rds, eParams, minLength, reUseBD);

  IvrLoggingTagWriter.from(EvrLoggingBDWriter writer)
      : inputOffsets = writer.inputOffsets,
        outputOffsets = (writer.inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(writer.rds),
        super.from(writer);
}
