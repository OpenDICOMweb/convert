// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/writer/base/ivr_writer.dart';
import 'package:dcm_convert/src/binary/base/writer/debug/log_write_mixin.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';

final bool elementOffsetsEnabled = true;

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class IvrByteWriter extends IvrWriter with LogWriteMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;
  @override
  int elementCount;

  /// Creates a new [IvrByteWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrByteWriter(RootDataset rds, EncodingParameters eParams, int minBDLength,
      bool reUseBD, this.inputOffsets)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super(rds, eParams, minBDLength, reUseBD);

  IvrByteWriter.from(IvrByteWriter writer)
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super.from(writer.rds, writer.eParams, writer.minBDLength, reUseBD);
}
