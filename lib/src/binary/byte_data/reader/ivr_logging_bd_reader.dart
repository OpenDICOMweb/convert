// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:dcm_convert/src/binary/byte_data/reader/evr_logging_bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/ivr_bd_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrLogReaderBD extends IvrReaderBD {
  /// Creates a new [IvrLogReaderBD].
  IvrLogReaderBD(ByteData bd, BDRootDataset rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path: path, dParams: dParams, reUseBD: reUseBD);

  IvrLogReaderBD.from(EvrLogReaderBD reader) : super.from(reader);
}
