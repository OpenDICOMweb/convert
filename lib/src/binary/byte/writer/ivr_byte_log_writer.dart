// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/writer/ivr_writer.dart';
import 'package:dcm_convert/src/binary/base/writer/debug/log_write_mixin.dart';
import 'package:dcm_convert/src/binary/byte/writer/evr_byte_log_writer.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class IvrByteLogWriter extends IvrWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  /// Creates a new [IvrByteLogWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrByteLogWriter(RootDataset rds, EncodingParameters eParams, int minBDLength,
      bool reUseBD, this.inputOffsets)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super(rds, eParams, minBDLength, reUseBD);

  IvrByteLogWriter.from(EvrByteLogWriter writer)
      : inputOffsets = writer.inputOffsets,
        outputOffsets = (writer.inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(writer.rds),
        super(writer.rds, writer.eParams, writer.minBDLength, writer.reUseBD);
}
