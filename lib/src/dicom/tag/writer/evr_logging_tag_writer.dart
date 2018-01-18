// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/writer/evr_writer.dart';
import 'package:convert/src/dicom/base/writer/debug/log_write_mixin.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrLoggingTagWriter extends EvrWriter with LogWriteMixin {
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
  EvrLoggingTagWriter(RootDataset rds, EncodingParameters eParams, int minBDLength,
      bool reUseBD, this.inputOffsets)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super(rds, eParams, minBDLength, reUseBD);
}