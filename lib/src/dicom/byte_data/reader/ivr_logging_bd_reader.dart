// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/reader/debug/log_read_mixin.dart';
import 'package:convert/src/dicom/byte_data/reader/evr_logging_bd_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/ivr_bd_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrLoggingBDReader extends IvrBDReader with LogReadMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  /// Creates a new [IvrLoggingBDReader].
  IvrLoggingBDReader(ByteData bd, BDRootDataset rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super.internal(bd, rds, dParams, reUseBD);

  IvrLoggingBDReader.from(EvrLoggingBDReader reader)
      : pInfo = new ParseInfo(reader.rds),
        offsets = new ElementOffsets(),
        super.from(reader);
}
