// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/base/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/debug/log_read_mixin.dart';
import 'package:dcm_convert/src/binary/byte/reader/byte_reader_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';

final bool elementOffsetsEnabled = true;

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class EvrByteLogReader extends EvrReader with ByteReaderMixin, LogReadMixin {
  @override
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  factory EvrByteLogReader(ByteData bd,
      {String path = '',
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final rds = new RootDatasetByte(new RDSBytes(bd), path: path);
    return new EvrByteLogReader._(bd, rds, path, dParams, reUseBD);
  }

  /// Creates a new [EvrByteLogReader], which is decoder for Binary DICOM
  /// (application/dicom).
  EvrByteLogReader._(
      ByteData bd, RootDataset rds, String path, DecodingParameters dParams, bool reUseBD)
      : offsets = (elementOffsetsEnabled) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super(bd, rds, path, dParams, reUseBD);
}
