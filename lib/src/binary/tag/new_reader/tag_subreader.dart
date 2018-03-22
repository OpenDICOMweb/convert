// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/logging_subreader.dart';
import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/tag/new_reader/logging_bytes_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class TagEvrSubReader extends EvrSubReader with TagReaderMixin {
  @override
  final BDRootDataset rds;
  @override
  final ReadBuffer rb;

  TagEvrSubReader(DecodingParameters dParams,  RootDataset rds, this.rb)
      : rds = rds,
        super(dParams, rds);
}

class LoggingTagEvrSubReader extends LoggingEvrSubReader with TagReaderMixin {
  @override
  final BDRootDataset rds;
  @override
  final ReadBuffer rb;

  LoggingTagEvrSubReader(DecodingParameters dParams, RootDataset rds, this.rb)
      : rds = rds,
        super(dParams, rds);

  @override
  SubReader get subreader => this;
}

class TagIvrSubReader extends IvrSubReader with TagReaderMixin {
  @override
  BDRootDataset rds;
  @override
  ReadBuffer rb;

  TagIvrSubReader.from(TagEvrSubReader subreader)
      : rds = subreader.rds,
        rb = subreader.rb,
        super(subreader.dParams, subreader.rds);
}

class LoggingTagIvrSubReader extends LoggingIvrSubReader with TagReaderMixin {
  @override
  BDRootDataset rds;
  @override
  ReadBuffer rb;

  LoggingTagIvrSubReader.from(TagEvrSubReader subreader)
      : rds = subreader.rds,
        rb = subreader.rb,
        super(subreader.dParams, subreader.rds);

  @override
  SubReader get subreader => this;
}
