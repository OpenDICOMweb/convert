// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:convert/src/binary/base/writer/ivr_writer.dart';
import 'package:convert/src/binary/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/binary/byte_data/writer/evr_bd_writer.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

/// An encoder for Binary DICOM (application/dicom).
class IvrBDWriter extends IvrWriter<int> {
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

  /// Creates a new [IvrBDWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrBDWriter(this.rds, this.eParams, this.minLength, {this.reUseBD = false})
      : wb = getWriteBuffer(length: minLength, reUseBD: reUseBD),
        cds = rds;

  /// Creates a new [IvrBDWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrBDWriter._(this.rds, this.eParams, this.minLength, this.reUseBD);

  IvrBDWriter.from(EvrBDWriter writer)
      : wb = writer.wb,
        rds = writer.rds,
        eParams = writer.eParams,
        minLength = writer.minLength,
        reUseBD = writer.reUseBD,
        cds = writer.cds;
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrLoggingBDWriter extends IvrBDWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  /// Creates a new [IvrLoggingBDWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrLoggingBDWriter(
      RootDataset rds, EncodingParameters eParams, int minLength, this.inputOffsets,
      {bool reUseBD = false})
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super._(rds, eParams, minLength, reUseBD);

  IvrLoggingBDWriter.from(EvrLoggingBDWriter writer)
      : inputOffsets = writer.inputOffsets,
        outputOffsets = (writer.inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(writer.rds),
        super.from(writer);
}
