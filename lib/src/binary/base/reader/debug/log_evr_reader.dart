// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/base/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/debug/log_read_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// Creates a new [EvrReader]  where [rb].rIndex = 0.
abstract class LogEvrReader extends EvrReader with LogReadMixin {
  LogEvrReader(
      ByteData bd, RootDataset rds, String path, DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, path, dParams, reUseBD);
}
