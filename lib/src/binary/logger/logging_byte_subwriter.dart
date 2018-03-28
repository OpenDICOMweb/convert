// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/logger/logging_subwriter.dart';
import 'package:convert/src/binary/byte/new_writer/byte_subwriter.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingByteEvrSubWriter extends LoggingEvrSubWriter {
  @override
  final ByteEvrSubWriter subWriter;

  /// Creates a new [LoggingByteEvrSubWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  LoggingByteEvrSubWriter(RootDataset rds, EncodingParameters eParams,
      {TransferSyntax outputTS, bool doLogging = false})
      : subWriter = new ByteEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging),
        super(rds, eParams);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingByteIvrSubWriter extends LoggingIvrSubWriter {
  @override
  final ByteIvrSubWriter subWriter;

  /// Creates a new [LoggingByteIvrSubWriter], which is encoder for
  /// Binary DICOM (application/dicom).
  LoggingByteIvrSubWriter.from(LoggingByteEvrSubWriter subWriter,
      {TransferSyntax outputTS, bool doLogging = false})
      : subWriter = new ByteIvrSubWriter.from(subWriter.subWriter,
            outputTS: outputTS, doLogging: doLogging),
        super(subWriter.rds, subWriter.eParams);
}
