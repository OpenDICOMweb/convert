// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/reader/debug/log_read_mixin.dart';
import 'package:convert/src/dicom/base/reader/evr_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrBDReader extends EvrReader<int> {
  final bool isEvr = true;
  // final ByteData bd;
  @override
  final ReadBuffer rb;
  @override
  final BDRootDataset rds;
  @override
  final DecodingParameters dParams;
  final bool reUseBD;

  @override
  Dataset cds;

  /// Creates a new [EvrBDReader].
  EvrBDReader(ByteData bd, this.rds,
      {this.dParams = DecodingParameters.kNoChange, this.reUseBD = true})
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  /// Creates a new [EvrBDReader].
  EvrBDReader._(ByteData bd, this.rds, this.dParams, this.reUseBD)
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  @override
  Item makeItem(Dataset parent,
          Map<int, Element> eMap, [SQ sequence, ByteData bd]) =>
      new BDItem.fromBD(parent, eMap, sequence, bd);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrLoggingBDReader extends EvrBDReader with LogReadMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  /// Creates a new [EvrLoggingBDReader].
  EvrLoggingBDReader(ByteData bd, BDRootDataset rds,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super._(bd, rds, dParams, reUseBD);
}
