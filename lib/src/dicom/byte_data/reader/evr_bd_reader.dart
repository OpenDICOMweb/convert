// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/read_buffer.dart';
import 'package:convert/src/dicom/base/reader/evr_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

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
  EvrBDReader.internal(ByteData bd, this.rds, this.dParams, this.reUseBD)
      : rb = new ReadBuffer(bd),
        cds = rds {
    print('rds: $rds');
  }

  @override
  ElementList get elements => cds.elements;
/*
  @override
  BDElement makeElementFromBD(int code, int vrIndex, ByteData bd) =>
      Evr.make(code, vrIndex, bd);

  @override
  Element makeElementFromList(int code, int vrIndex, Iterable values) {
    final tag = Tag.lookupByCode(code);
    return TagElement.make(tag, vrIndex, values);
  }

  @override
  BDElement makePixelData(int code, int vrIndex, ByteData bd,
          [TransferSyntax ts, VFFragments fragments]) =>
      Evr.makePixelData(code, vrIndex, bd, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, ByteData bd, Dataset parent, Iterable<Item> items) =>
      Evr.makeSequence(code, bd, parent, items);

  @override
  RootDataset makeRootDataset({ByteData bd, ElementList elements, String path}) =>
      new BDRootDataset(bd, elements: elements, path: path);
*/
  @override
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new BDItem(parent, bd);
}
