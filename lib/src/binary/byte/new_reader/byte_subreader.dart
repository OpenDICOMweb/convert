// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/byte/new_reader/byte_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class ByteEvrSubReader extends EvrSubReader
    with ByteReaderMixin, EvrByteReaderMixin {
  @override
  final BDRootDataset rds;
  @override
  final bool doLogging;

  factory ByteEvrSubReader(Bytes bytes, DecodingParameters dParams,
          {bool doLogging = false}) =>
      new ByteEvrSubReader._(
          bytes, dParams, new BDRootDataset.empty(), doLogging);

  ByteEvrSubReader._(
      Bytes bytes, DecodingParameters dParams, this.rds, this.doLogging)
      : super(bytes, dParams, rds);
}

class ByteIvrSubReader extends IvrSubReader
    with ByteReaderMixin, IvrByteReaderMixin {
  @override
  BDRootDataset rds;
  @override
  final bool doLogging;

  ByteIvrSubReader.from(ByteEvrSubReader evrSubReader,
      {bool doLookupVRIndex = false})
      : rds = evrSubReader.rds,
        doLogging = evrSubReader.doLogging,
        super(evrSubReader.rb, evrSubReader.dParams, evrSubReader.rds,
            doLookupVRIndex);
}
