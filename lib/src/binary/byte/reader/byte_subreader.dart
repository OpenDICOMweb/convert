//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:converter/src/binary/base/reader/subreader.dart';
import 'package:converter/src/binary/byte/reader/byte_reader_mixin.dart';
import 'package:converter/src/decoding_parameters.dart';

class ByteEvrSubReader extends EvrSubReader with ByteReaderMixin {
  @override
  final ByteRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;
  factory ByteEvrSubReader(Bytes bytes, DecodingParameters dParams,
          {bool doLogging = false, bool doLookupVRIndex = true}) =>
      new ByteEvrSubReader._(bytes, dParams, new ByteRootDataset.empty(),
          doLogging, doLookupVRIndex);

  ByteEvrSubReader._(Bytes bytes, DecodingParameters dParams, this.rds,
      this.doLogging, this.doLookupVRIndex)
      : super(bytes, dParams, rds);
}

class ByteIvrSubReader extends IvrSubReader with ByteReaderMixin {
  @override
  ByteRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;

  ByteIvrSubReader.from(ByteEvrSubReader evrSubReader)
      : rds = evrSubReader.rds,
        doLogging = evrSubReader.doLogging,
        doLookupVRIndex = evrSubReader.doLookupVRIndex,
        super(evrSubReader.rb, evrSubReader.dParams, evrSubReader.rds);
}
