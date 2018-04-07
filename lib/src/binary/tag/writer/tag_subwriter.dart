// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/subwriter.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

/// An encoder for Binary DICOM (application/dicom).
class TagEvrSubWriter extends EvrSubWriter {
  @override
  final TagRootDataset rds;
  @override
  final TransferSyntax outputTS;
  @override
  final bool doLogging;

  /// Creates a new [TagEvrSubWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  TagEvrSubWriter(this.rds, EncodingParameters eParams,
      {this.outputTS, this.doLogging = false})
      : super(rds, eParams);
}

/// An encoder for Binary DICOM (application/dicom).
class TagIvrSubWriter extends IvrSubWriter {
  @override
  final TagRootDataset rds;
  @override
  final TransferSyntax outputTS;
  @override
  final bool doLogging;

  /// Creates a new [TagIvrSubWriter], which is decoder for Binary DICOM
  /// (application/dicom).
/*
  TagIvrSubWriter(this.rds, EncodingParameters eParams,
      {this.outputTS, this.doLogging = false})
      : super(rds, eParams);
*/

  TagIvrSubWriter.from(TagEvrSubWriter subWriter,
      {this.outputTS, this.doLogging = false})
      : rds = subWriter.rds,
        super(subWriter.rds, subWriter.eParams, subWriter.wb);
}
