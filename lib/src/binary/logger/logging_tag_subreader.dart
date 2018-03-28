// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/logger/logging_subreader.dart';
import 'package:convert/src/binary/logger/logging_tag_reader.dart';
import 'package:convert/src/binary/tag/new_reader/tag_subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class LoggingTagEvrSubReader extends LoggingEvrSubReader with TagReaderMixin {
  @override
  final TagEvrSubReader subReader;

  LoggingTagEvrSubReader(
      Bytes bytes, DecodingParameters dParams, TagRootDataset rds,
      {bool doLogging = false})
      : subReader =
            new TagEvrSubReader(bytes, dParams, rds, doLogging: doLogging),
        super();
}

class LoggingTagIvrSubReader extends LoggingIvrSubReader with TagReaderMixin {
  @override
  final TagIvrSubReader subReader;

  LoggingTagIvrSubReader.from(TagEvrSubReader evrSubReader)
      : subReader = new TagIvrSubReader.from(evrSubReader),
        super();
}
