//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';

import 'package:converter/src/binary/base/reader/subreader.dart';
import 'package:converter/src/binary/tag/reader/tag_reader_mixin.dart';
import 'package:converter/src/decoding_parameters.dart';

class TagEvrSubReader extends EvrSubReader with TagReaderMixin {
  @override
  final TagRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;

  factory TagEvrSubReader(Bytes bytes, DecodingParameters dParams,
      {bool doLogging = false, bool doLookupVRIndex = true}) =>
      TagEvrSubReader._(bytes, dParams, TagRootDataset.empty(),
          doLogging, doLookupVRIndex);

  TagEvrSubReader._(Bytes bytes, DecodingParameters dParams, this.rds,
      this.doLogging, this.doLookupVRIndex)
      : super(bytes, dParams, rds);
}

class TagIvrSubReader extends IvrSubReader with TagReaderMixin {
  @override
  TagRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;

  TagIvrSubReader.from(TagEvrSubReader evrSubReader)
      : rds = evrSubReader.rds,
        doLogging = evrSubReader.doLogging,
        doLookupVRIndex = evrSubReader.doLookupVRIndex,
        super(evrSubReader.rb, evrSubReader.dParams, evrSubReader.rds);
}
