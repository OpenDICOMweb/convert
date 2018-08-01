//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:converter/src/binary/base/reader/reader.dart';
import 'package:converter/src/binary/base/reader/subreader.dart';
import 'package:converter/src/binary/tag/reader/tag_subreader.dart';
import 'package:converter/src/decoding_parameters.dart';

/// Creates a new [TagReader], which is a decoder for Binary DICOM
/// (application/dicom).
class TagReader extends Reader {
  @override
  final EvrSubReader evrSubReader;

  /// Creates a new [TagReader], which is decoder for Binary
  /// DICOM (application/dicom).
  factory TagReader(Uint8List bList,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final bytes = new Bytes.typedDataView(bList);
    final rds = new TagRootDataset.empty();
    return new TagReader._(bytes, dParams, rds, doLogging: doLogging);
  }

  /// Creates a new [TagReader].
  TagReader._(Bytes bytes, DecodingParameters dParams, TagRootDataset rds,
      {bool doLogging: false})
      : evrSubReader = //(doLogging)
            // ? new LoggingTagEvrSubReader(bytes, dParams, rds)
            new TagEvrSubReader(bytes, dParams, rds, doLogging: doLogging),
        super(bytes);

  /// Creates a new [TagReader], which is decoder for Binary
  /// DICOM (application/dicom).
  factory TagReader.fromBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final rds = new TagRootDataset.empty();
    return new TagReader._(bytes, dParams, rds, doLogging: doLogging);
  }

  @override
  IvrSubReader get ivrSubReader => _ivrSubReader ??= //(doLogging)
      //  ? new LoggingTagIvrSubReader.from(evrSubReader)
      new TagIvrSubReader.from(evrSubReader);
  TagIvrSubReader _ivrSubReader;

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final reader =
        new TagReader.fromBytes(bytes, dParams: dParams, doLogging: doLogging);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readTypedData(TypedData td,
      {Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    assert(td is Uint8List || td is ByteData);
    final bytes = new Bytes.typedDataView(td,0, td.lengthInBytes, endian);
    return TagReader.readBytes(bytes, dParams: dParams, doLogging: doLogging);
  }
}

