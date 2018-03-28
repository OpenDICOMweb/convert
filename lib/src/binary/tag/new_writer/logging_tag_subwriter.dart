// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_writer/logging_subwriter.dart';
import 'package:convert/src/binary/tag/new_writer/tag_subwriter.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingTagEvrSubWriter extends LoggingEvrSubWriter {
  @override
  final TagEvrSubWriter subWriter;

  /// Creates a new [LoggingTagEvrSubWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  LoggingTagEvrSubWriter(RootDataset rds, EncodingParameters eParams,
      {TransferSyntax outputTS, bool doLogging = false})
      : subWriter = new TagEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging),
        super(rds, eParams);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingTagIvrSubWriter extends LoggingIvrSubWriter {
  @override
  final TagIvrSubWriter subWriter;

  /// Creates a new [LoggingTagIvrSubWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  LoggingTagIvrSubWriter.from(LoggingTagEvrSubWriter subWriter,
      {TransferSyntax outputTS, bool doLogging = false})
      : subWriter = new TagIvrSubWriter.from(subWriter.subWriter,
            outputTS: outputTS, doLogging: doLogging),
        super(subWriter.rds, subWriter.eParams);
}
