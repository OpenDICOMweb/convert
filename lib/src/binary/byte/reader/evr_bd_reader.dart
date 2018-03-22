// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/debug/log_read_mixin.dart';
import 'package:convert/src/binary/base/reader/evr_reader.dart';
import 'package:convert/src/binary/bytes/reader/bd_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrByteReader extends EvrReader<int> with ByteReaderMixin {
  final bool isEvr = true;
  // final Bytes bd;
  @override
  final ReadBuffer rb;
  @override
  final BDRootDataset rds;
  @override
  final DecodingParameters dParams;
  final bool reUseBD;

  @override
  Dataset cds;

  /// Creates a new [EvrByteReader].
  EvrByteReader(Bytes bytes, this.rds,
      {this.dParams = DecodingParameters.kNoChange, this.reUseBD = true})
      : rb = new ReadBuffer(bytes),
        cds = rds;

  /// Creates a new [EvrByteReader].
  EvrByteReader._(Bytes bytes, this.rds, this.dParams, this.reUseBD)
      : rb = new ReadBuffer(bytes),
        cds = rds;

  @override
  Item makeItem(Dataset parent, [SQ sequence, Map<int, Element> eMap,
           Bytes bd]) =>
      new BDItem.fromBD(parent, sequence, eMap ?? <int, Element>{}, bd);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrLoggingByteReader extends EvrByteReader with LogReadMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  /// Creates a new [EvrLoggingByteReader].
  EvrLoggingByteReader(Bytes bd, BDRootDataset rds,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super._(bd, rds, dParams, reUseBD);
}
