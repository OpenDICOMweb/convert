// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/reader/evr_reader.dart';
import 'package:convert/src/dicom/base/reader/debug/log_read_mixin.dart';
import 'package:convert/src/dicom/tag/reader/ivr_tag_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [TagRootDataset].
class EvrTagReader extends EvrReader<int> {
  final bool isEvr = true;
  @override
  final ReadBuffer rb;
  @override
  final TagRootDataset rds;
  @override
  final DecodingParameters dParams;
  final bool reUseBD;

  @override
  Dataset cds;

  /// Creates a new [EvrTagReader].
  EvrTagReader(ByteData bd, this.rds,
      {this.dParams = DecodingParameters.kNoChange, this.reUseBD = true})
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  /// Creates a new [EvrTagReader].
  EvrTagReader.from(IvrTagReader reader)
      : rb = reader.rb,
        rds = reader.rds,
        dParams = reader.dParams,
        reUseBD = reader.reUseBD,
        cds = reader.cds {
    print('rds: $rds');
  }

  /// Creates a new [EvrTagReader].
  EvrTagReader._(ByteData bd, this.rds, this.dParams, this.reUseBD)
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  @override
  Item makeItem(Dataset parent, Map<int, Element> eMap,
          [SQ sequence, ByteData bd]) =>
      new BDItem.fromBD(parent, eMap, sequence, bd);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [TagRootDataset].
class EvrLoggingTagReader extends EvrTagReader with LogReadMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  /// Creates a new [EvrLoggingTagReader].
  EvrLoggingTagReader(ByteData bd, TagRootDataset rds,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super._(bd, rds, dParams, reUseBD);
}
