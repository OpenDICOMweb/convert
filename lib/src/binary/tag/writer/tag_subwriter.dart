//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:converter/src/binary/base/writer/subwriter.dart';
import 'package:converter/src/encoding_parameters.dart';

/// An encoder for Binary DICOM (application/dicom).
class TagEvrSubWriter extends EvrSubWriter {
  @override
  final TagRootDataset rds;
  @override
  final bool doLogging;

  /// Creates a new [TagEvrSubWriter], which is an encoder for Binary DICOM
  /// (application/dicom).
  TagEvrSubWriter(this.rds, EncodingParameters eParams,
      {TransferSyntax outputTS, this.doLogging = false})
      : super(rds, eParams, outputTS);
}

/// An encoder for Binary DICOM (application/dicom).
class TagIvrSubWriter extends IvrSubWriter {
  @override
  final TagRootDataset rds;
  @override
  final bool doLogging;

  /// Creates a new [TagIvrSubWriter], which is decoder for Binary DICOM
  /// (application/dicom).
/*
  TagIvrSubWriter(this.rds, EncodingParameters eParams,
      {this.outputTS, this.doLogging = false})
      : super(rds, eParams);
*/

  TagIvrSubWriter.from(TagEvrSubWriter subWriter, {this.doLogging = false})
      : rds = subWriter.rds,
        super.from(subWriter);
}
