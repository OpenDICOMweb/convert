// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/reader/ivr_reader.dart';
import 'package:convert/src/dicom/base/reader/log_read_mixin_base.dart';
import 'package:convert/src/dicom/tag/reader/evr_tag_reader.dart';
import 'package:convert/src/dicom/tag/reader/tag_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrTagReader extends IvrReader<int> with TagReaderMixin,
    LogReadMixinBase {
  /// Creates a new [IvrTagReader].
  IvrTagReader(ByteData bd, BDRootDataset rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD);

  IvrTagReader.from(EvrTagReader reader) : super.from(reader);

  @override
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new BDItem(parent, bd);

/*
  @override
  Element makeBDElement(int code, int vrIndex, BDElement bd) =>
      Ivr.make(code, vrIndex, bd);

  @override
  Element makePixelData(int code, int vrIndex, BDElement bd,
                        [TransferSyntax ts, VFFragments fragments]) =>
      Ivr.makePixelData(code, vrIndex, bd, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, BDElement bd, Dataset parent, Iterable<Item> items) =>
      Ivr.makeSequence(code, bd, parent, items);
*/

}
