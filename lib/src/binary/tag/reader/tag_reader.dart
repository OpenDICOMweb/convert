//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:io';
import 'dart:typed_data';

import 'package:bytes_dicom/bytes_dicom.dart';
import 'package:core/core.dart';

import 'package:converter/src/binary/base/reader/reader.dart';
import 'package:converter/src/binary/base/reader/subreader.dart';
import 'package:converter/src/binary/tag/reader/tag_subreader.dart';
import 'package:converter/src/decoding_parameters.dart';

// ignore_for_file: public_member_api_docs

/// Creates a [TagReader], which is a decoder for Binary DICOM
/// (application/dicom).
class TagReader extends Reader {
  @override
  final EvrSubReader evrSubReader;

  /// Creates a [TagReader], which is decoder for Binary
  /// DICOM (application/dicom).
  factory TagReader(Uint8List bList,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool doLogging = false}) =>
      TagReader.fromBytes(Bytes.typedDataView(bList),
          dParams: dParams, doLogging: doLogging);

  /// Creates a [TagReader], which is decoder for Binary
  /// DICOM (application/dicom).
  TagReader.fromBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false})
      : evrSubReader = TagEvrSubReader(bytes, dParams, doLogging: doLogging),
        super(bytes);

  factory TagReader.fromFile(File f,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final Uint8List bList = f.readAsBytesSync();
    final bytes = Bytes.typedDataView(bList);
    return TagReader.fromBytes(bytes, dParams: dParams, doLogging: doLogging);
  }

  factory TagReader.fromPath(String path,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final f = File(path);
    return TagReader.fromFile(f, dParams: dParams, doLogging: doLogging);
  }

  @override
  IvrSubReader get ivrSubReader =>
      _ivrSubReader ??= TagIvrSubReader.from(evrSubReader);
  TagIvrSubReader _ivrSubReader;

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final reader =
        TagReader.fromBytes(bytes, dParams: dParams, doLogging: doLogging);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readTypedData(TypedData td,
      {Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    assert(td is Uint8List || td is ByteData);
    final bytes = Bytes.typedDataView(td, 0, td.lengthInBytes, endian);
    return TagReader.readBytes(bytes, dParams: dParams, doLogging: doLogging);
  }

  // Issue: maybe remove
  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(File file,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    checkFile(file);
    final Uint8List td = file.readAsBytesSync();
    return TagReader.readTypedData(td,
        endian: endian, dParams: dParams, doLogging: doLogging);
  }

  // Issue: maybe remove
  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(String path,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    checkPath(path);
    return TagReader.readFile(File(path),
        doAsync: doAsync,
        endian: endian,
        dParams: dParams,
        doLogging: doLogging);
  }

}
