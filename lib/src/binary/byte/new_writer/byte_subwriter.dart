// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_writer/subwriter.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

/// An encoder for Binary DICOM (application/dicom).
class ByteEvrSubWriter extends EvrSubWriter {
  @override
  final BDRootDataset rds;
  @override
  final TransferSyntax outputTS;
  @override
  final bool doLogging;

  /// Creates a new [ByteEvrSubWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  ByteEvrSubWriter(this.rds, EncodingParameters eParams,
      {this.outputTS, this.doLogging = false})
      : super(rds, eParams);
}

/// An encoder for Binary DICOM (application/dicom).
class ByteIvrSubWriter extends IvrSubWriter {
  @override
  final BDRootDataset rds;
  @override
  final TransferSyntax outputTS;
  @override
  final bool doLogging;

  /// Creates a new [ByteIvrSubWriter], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteIvrSubWriter(this.rds, EncodingParameters eParams,
      {this.outputTS, this.doLogging = false})
      : super(rds, eParams);

  ByteIvrSubWriter.from(ByteEvrSubWriter subWriter)
      : rds = subWriter.rds,
        outputTS = subWriter.outputTS,
        doLogging = subWriter.doLogging,
        super(subWriter.rds, subWriter.eParams);
}
