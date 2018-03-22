// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/logging_subreader.dart';
import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/byte/new_reader/logging_byte_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class ByteEvrSubReader extends EvrSubReader with ByteReaderMixin {
  @override
  final BDRootDataset rds;
  @override
  final ReadBuffer rb;

  ByteEvrSubReader(DecodingParameters dParams,  RootDataset rds, this.rb)
      : rds = rds,
        super(dParams, rds);
}

class LoggingByteEvrSubReader extends LoggingEvrSubReader with ByteReaderMixin {
  @override
  final BDRootDataset rds;
  @override
  final ReadBuffer rb;

  LoggingByteEvrSubReader(DecodingParameters dParams, RootDataset rds, this.rb)
      : rds = rds,
        super(dParams, rds);

  @override
  SubReader get subreader => this;
}

class ByteIvrSubReader extends IvrSubReader with ByteReaderMixin {
  @override
  BDRootDataset rds;
  @override
  ReadBuffer rb;

  ByteIvrSubReader.from(ByteEvrSubReader subreader)
      : rds = subreader.rds,
        rb = subreader.rb,
        super(subreader.dParams, subreader.rds);
}

class LoggingByteIvrSubReader extends LoggingIvrSubReader with ByteReaderMixin {
  @override
  BDRootDataset rds;
  @override
  ReadBuffer rb;

  LoggingByteIvrSubReader.from(ByteEvrSubReader subreader)
      : rds = subreader.rds,
        rb = subreader.rb,
        super(subreader.dParams, subreader.rds);

  @override
  SubReader get subreader => this;
}
