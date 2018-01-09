// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/bd_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/log_read_mixin_base.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/bd_reader_mixin.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/tag_reader_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class EvrTagReader extends EvrReader with BDReaderMixin, TagReaderMixin,
    LogReadMixinBase {
  /// Creates a new [EvrTagReader].
  EvrTagReader(ByteData bd, TagRootDataset rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD);

  /// Creates a new [EvrTagReader].
  EvrTagReader.internal(ByteData bd, TagRootDataset rds, String path,
      DecodingParameters dParams, bool reUseBD)
      : super(bd, rds, path, dParams, reUseBD);

/*
  @override
  Element makeBDElement(int code, int vrIndex, ByteData bd) =>
      TagElement.fromBD(Evr.make(code, vrIndex, bd));

  @override
  Element makeTagPixelData(int code, int vrIndex, BDElement bd,
          [TransferSyntax ts, VFFragments fragments]) =>
      TagElement.makePixelData(code, vrIndex, bd, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  @override
  SQtag makeSequence(int code, ByteData bd, Dataset parent, Iterable<Item> items) {
    final bde = Evr.makeSequence(code, bd, parent, items);
    return new SQtag(bde.tag, parent, items, bde.vfLengthField);
  }
*/

}
