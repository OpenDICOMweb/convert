// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/writer/evr_writer.dart';
import 'package:dcm_convert/src/binary/base/writer/log_write_mixin_base.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// An encoder for Binary DICOM (application/dicom).
class EvrByteWriter extends EvrWriter with LogWriteMixinBase {

  /// Creates a new [EvrByteWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  EvrByteWriter(
      RootDataset rds, EncodingParameters eParams, int minBDLength, bool reUseBD)
      : super(rds, eParams, minBDLength, reUseBD);
}