// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:dcm_convert/src/binary/base/reader/ivr_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/evr_bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/bd_reader_mixin.dart';
import 'package:dcm_convert/src/binary/tag/reader/tag_reader_mixin.dart';
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

  static final BDElementMaker make = Ivr.make;
}
