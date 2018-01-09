// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/bd_dataset.dart';
import 'package:element/bd_element.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/ivr_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/evr_bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/bd_reader_mixin.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/tag_reader_mixin.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrReaderBD extends IvrReader<int> with BDReaderMixin, TagReaderMixin {
  /// Creates a new [IvrReaderBD].
  IvrReaderBD(ByteData bd, BDRootDataset rds,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : super(bd, rds, path, dParams, reUseBD);

  IvrReaderBD.from(EvrReaderBD reader) : super.from(reader);

/*
  @override
  Element makeElementFromBD(int code, int vrIndex, ByteData bd) =>
      Ivr.make(code, vrIndex, bd);

  @override
  Element makePixelData(int code, int vrIndex, ByteData bd,
          [TransferSyntax ts, VFFragments fragments]) =>
      Ivr.makePixelData(code, vrIndex, bd, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, Dataset parent, Iterable<Item> items, [ByteData bd]) =>
      Ivr.makeSequence(code, bd, parent, items);
*/

  static final BDElementMaker make = Ivr.make;
}
