//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:io/io.dart';

import 'package:convert/src/binary/base/reader/reader.dart';
import 'package:convert/src/binary/base/reader/subreader.dart';
import 'package:convert/src/binary/tag/reader/tag_subreader.dart';
import 'package:convert/src/decoding_parameters.dart';

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

  factory TagReader.fromFile(File f,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final bList = f.readAsBytesSync();
    return new TagReader.fromBytes(bList,
        dParams: dParams, doLogging: doLogging);
  }

  factory TagReader.fromPath(String path,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final f = new File(path);
    return TagReader.fromFile(f, dParams: dParams, doLogging: doLogging);
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
