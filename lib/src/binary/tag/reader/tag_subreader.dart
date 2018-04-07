// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/subreader.dart';
import 'package:convert/src/binary/tag/reader/tag_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class TagEvrSubReader extends EvrSubReader with TagReaderMixin {
  @override
  final TagRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;

  TagEvrSubReader(Bytes bytes, DecodingParameters dParams, this.rds,
      {this.doLogging = false, this.doLookupVRIndex = true})
      : super(bytes, dParams, rds);
}

class TagIvrSubReader extends IvrSubReader with TagReaderMixin {
  @override
  TagRootDataset rds;
  @override
  final bool doLogging;
  @override
  final bool doLookupVRIndex;

  TagIvrSubReader.from(TagEvrSubReader subReader)
      : rds = subReader.rds,
        doLogging = subReader.doLogging,
        doLookupVRIndex = subReader.doLookupVRIndex,
        super(subReader.rb, subReader.dParams, subReader.rds);
}
