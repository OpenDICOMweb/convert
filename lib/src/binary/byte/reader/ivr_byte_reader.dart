// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/ivr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/log_read_mixin_base.dart';
import 'package:dcm_convert/src/binary/byte/reader/byte_reader_mixin.dart';
import 'package:dcm_convert/src/binary/byte/reader/evr_byte_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class IvrByteReader extends IvrReader with ByteReaderMixin, LogReadMixinBase {
  factory IvrByteReader(ByteData bd,
      {String path = '',
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final rds = new RootDatasetByte(new RDSBytes(bd), path: path);
    return new IvrByteReader._(bd, rds, path, dParams, reUseBD);
  }

  /// Creates a new [IvrByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrByteReader._(
      ByteData bd, RootDataset rds, String path, DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, path, dParams, reUseBD);

  IvrByteReader.from(EvrByteReader reader) : super.from(reader);
}
