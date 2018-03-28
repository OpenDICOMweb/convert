// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/tag/new_reader/logging_tag_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class TagEvrSubReader extends EvrSubReader with TagReaderMixin {
  @override
  final TagRootDataset rds;
  @override
  final bool doLogging;

  TagEvrSubReader(Bytes bytes, DecodingParameters dParams, this.rds,
      {this.doLogging = false})
      : super(bytes, dParams, rds);
}

class TagIvrSubReader extends IvrSubReader with TagReaderMixin {
  @override
  TagRootDataset rds;
  @override
  final bool doLogging;

  TagIvrSubReader.from(TagEvrSubReader subReader,
      {bool doLookupVRIndex = false})
      : rds = subReader.rds,
        doLogging = subReader.doLogging,
        super(subReader.rb, subReader.dParams, subReader.rds, doLookupVRIndex);
}
