// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/ivr_writer.dart';
import 'package:convert/src/binary/base/writer/log_write_mixin_base.dart';
import 'package:convert/src/binary/byte_data/writer/evr_bd_writer.dart';
import 'package:convert/src/encoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// An encoder for Binary DICOM (application/dicom).
class IvrBDWriter extends IvrWriter with LogWriteMixinBase {

  /// Creates a new [IvrBDWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  IvrBDWriter(
      RootDataset rds, EncodingParameters eParams, int minBDLength, bool reUseBD)
      : super(rds, eParams, minBDLength, reUseBD);

  IvrBDWriter.from(EvrBDWriter writer) : super.from(writer);
}