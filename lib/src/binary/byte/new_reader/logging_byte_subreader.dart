// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/logging_subreader.dart';
import 'package:convert/src/binary/byte/new_reader/byte_reader_mixin.dart';
import 'package:convert/src/binary/byte/new_reader/byte_subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';

class LoggingByteEvrSubReader extends LoggingEvrSubReader
    with ByteReaderMixin, EvrByteReaderMixin {
  @override
  final ByteEvrSubReader subReader;

  LoggingByteEvrSubReader(Bytes bytes, DecodingParameters dParams,
      {bool doLogging = false})
      : subReader = new ByteEvrSubReader(bytes, dParams, doLogging: doLogging),
        super();
}

class LoggingByteIvrSubReader extends LoggingIvrSubReader
    with ByteReaderMixin, EvrByteReaderMixin {
  @override
  final ByteIvrSubReader subReader;

  LoggingByteIvrSubReader.from(ByteEvrSubReader evrSubReader,
      {bool doLookupVRIndex = false})
      : subReader = new ByteIvrSubReader.from(evrSubReader,
            doLookupVRIndex: doLookupVRIndex),
        super();
}
