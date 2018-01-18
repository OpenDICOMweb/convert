// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/read_buffer.dart';
import 'package:convert/src/dicom/base/reader/ivr_reader.dart';
import 'package:convert/src/dicom/base/reader/debug/log_read_mixin.dart';
import 'package:convert/src/dicom/tag/reader/evr_tag_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrTagReader extends IvrReader<int> {
  final bool isEvr = false;
  @override
  final ReadBuffer rb;
  @override
  final TagRootDataset rds;
  final DecodingParameters dParams;
  final bool reUseBD;

  @override
  Dataset cds;

  /// Creates a new [IvrTagReader].
  IvrTagReader(ByteData bd, this.rds,
      {this.dParams = DecodingParameters.kNoChange, this.reUseBD = true})
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  IvrTagReader.from(EvrTagReader reader)
      : rb = reader.rb,
        rds = reader.rds,
        dParams = reader.dParams,
        reUseBD = reader.reUseBD,
        cds = reader.cds {
    print('rds: $rds');
  }

  /// Creates a new [EvrTagReader].
  IvrTagReader._(ByteData bd, this.rds, this.dParams, this.reUseBD)
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  @override
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new BDItem(parent, bd);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [TagRootDataset].
class IvrLoggingTagReader extends IvrTagReader with LogReadMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  /// Creates a new [EvrLoggingTagReader].
  IvrLoggingTagReader(ByteData bd, TagRootDataset rds,
      {DecodingParameters dParams = DecodingParameters.kNoChange, bool reUseBD = true})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super._(bd, rds, dParams, reUseBD);

  IvrLoggingTagReader.from(EvrTagReader reader)
      : pInfo = new ParseInfo(reader.rds),
        offsets = new ElementOffsets(),
        super.from(reader) {
    print('rds: $rds');
  }
}
