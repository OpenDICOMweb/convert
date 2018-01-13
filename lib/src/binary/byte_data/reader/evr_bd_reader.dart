// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';
import 'package:dcm_convert/src/binary/tag/reader/tag_reader_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrReaderBD extends EvrReader with TagReaderMixin {
  /// Creates a new [EvrReaderBD].
  EvrReaderBD(ByteData bd, BDRootDataset rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD);

  /// Creates a new [EvrReaderBD].
  EvrReaderBD.internal(ByteData bd, BDRootDataset rds, String path,
      DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, path, dParams, reUseBD);

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
  SQ makeSequence(int code, Dataset parent, Iterable<Item> items, [ByteData bd]) =>
      Evr.makeSequence(code, bd, parent, items);

  @override
  RootDataset makeRootDataset({ByteData bd, ElementList elements, String path}) =>
      new BDRootDataset(bd, elements: elements, path: path);

  @override
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new BDItem(parent, bd);
}
