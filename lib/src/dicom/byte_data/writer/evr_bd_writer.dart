// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/byte_list/write_buffer.dart';
import 'package:convert/src/dicom/base/writer/dcm_writer_base.dart';
import 'package:convert/src/dicom/base/writer/evr_writer.dart';
import 'package:convert/src/dicom/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

/// An encoder for Binary DICOM (application/dicom).
class EvrBDWriter extends EvrWriter<int> {
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

  /// Creates a new [EvrBDWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  EvrBDWriter(this.rds, this.eParams, this.minLength, {this.reUseBD = false})
: wb = getWriteBuffer(length: minLength, reUseBD: reUseBD),
        cds = rds;

  /// Creates a new [EvrBDWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  EvrBDWriter._(this.rds, this.eParams, this.minLength, this.reUseBD)
  : cds = rds;
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrLoggingBDWriter extends EvrBDWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  /// Creates a new [EvrLoggingBDWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  EvrLoggingBDWriter(
      RootDataset rds, EncodingParameters eParams, int minBDLength, this.inputOffsets,
      {bool reUseBD = false})
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super._(rds, eParams, minBDLength, reUseBD);
}
