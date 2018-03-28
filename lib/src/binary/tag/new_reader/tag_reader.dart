// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/reader.dart';
import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/tag/new_reader/tag_subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

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
    final bytes = new Bytes.fromTypedData(bList);
    final rds = new TagRootDataset.empty();
    return new TagReader._(bytes, dParams, doLogging, rds);
  }

  /// Creates a new [TagReader].
  TagReader._(Bytes bytes, DecodingParameters dParams, bool doLogging,
      TagRootDataset rds)
      : evrSubReader = //(doLogging)
           // ? new LoggingTagEvrSubReader(bytes, dParams, rds)
             new TagEvrSubReader(bytes, dParams, rds),
        super(bytes, doLogging: doLogging);

  /// Creates a new [TagReader], which is decoder for Binary
  /// DICOM (application/dicom).
  factory TagReader.fromBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final rds = new TagRootDataset.empty();
    return new TagReader._(bytes, dParams, doLogging, rds);
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
    final bytes = new Bytes.fromTypedData(td, endian);
    return TagReader.readBytes(bytes, dParams: dParams, doLogging: doLogging);
  }

  /// Reads the [TagRootDataset] from a [File].
  static TagRootDataset readFile(File file,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    checkFile(file);
    final Uint8List td = file.readAsBytesSync();
    return TagReader.readTypedData(td, dParams: dParams, doLogging: doLogging);
  }

  /// Reads the [TagRootDataset] from a [path] ([File] or URL).
  static TagRootDataset readPath(String path,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    checkPath(path);
    return TagReader.readFile(new File(path),
        doAsync: doAsync,
        endian: endian,
        dParams: dParams,
        doLogging: doLogging);
  }
}

/*  TODO: later
Future<Uint8List> _readFileAsync(File file) async =>
 await file.readAsBytes();
*/
