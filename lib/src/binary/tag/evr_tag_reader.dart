// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/log_read_mixin_base.dart';
import 'package:dcm_convert/src/binary/tag/tag_reader_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class EvrTagReader extends EvrReader with TagReaderMixin, LogReadMixinBase {
  /// Creates a new [EvrTagReader].
  EvrTagReader(ByteData bd, RootDatasetTag rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD);

  /// Creates a new [EvrTagReader].
  EvrTagReader.internal(ByteData bd, RootDatasetTag rds, String path,
      DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, path, dParams, reUseBD);
}