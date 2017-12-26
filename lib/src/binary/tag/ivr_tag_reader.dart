// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/ivr_reader.dart';
import 'package:dcm_convert/src/binary/tag/evr_tag_reader.dart';
import 'package:dcm_convert/src/binary/tag/tag_reader_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class IvrTagReader extends IvrReader with TagReaderMixin {
  /// Creates a new [IvrTagReader].
  IvrTagReader(ByteData bd, RootDatasetByte rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD);

  IvrTagReader.from(EvrTagReader reader) : super.from(reader);
}