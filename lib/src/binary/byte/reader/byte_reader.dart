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

import 'package:core/core.dart';

import 'package:converter/src/binary/base/reader/reader.dart';
import 'package:converter/src/binary/base/reader/subreader.dart';
import 'package:converter/src/binary/byte/reader/byte_subreader.dart';
import 'package:converter/src/decoding_parameters.dart';

/// Creates a new [ByteReader], which is a decoder for Binary DICOM
/// (application/dicom).
class ByteReader extends Reader {
  @override
  final EvrSubReader evrSubReader;

  /// Creates a new [ByteReader], which is decoder for Binary
  /// DICOM (application/dicom).
  factory ByteReader(Uint8List bList,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool doLogging = false}) =>
      new ByteReader.fromBytes(new Bytes.typedDataView(bList),
          dParams: dParams, doLogging: doLogging);

  /// Creates a new [ByteReader].
  ByteReader.fromBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false})
      : evrSubReader =
            //  ? new LoggingByteEvrSubReader(bytes, dParams)
            new ByteEvrSubReader(bytes, dParams, doLogging: doLogging),
        super(bytes);

  factory ByteReader.fromFile(File f,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final Uint8List bList = f.readAsBytesSync();
    final bytes = new Bytes.typedDataView(bList);
    return new ByteReader.fromBytes(bytes,
        dParams: dParams, doLogging: doLogging);
  }

  factory ByteReader.fromPath(String path,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final f = new File(path);
    return new ByteReader.fromFile(f, dParams: dParams, doLogging: doLogging);
  }

  /// Returns a new [ByteIvrSubReader], which is created lazily on demand.
  @override
  ByteIvrSubReader get ivrSubReader =>
      _ivrSubReader ??= new ByteIvrSubReader.from(evrSubReader);
  ByteIvrSubReader _ivrSubReader;

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final reader =
        new ByteReader.fromBytes(bytes, dParams: dParams, doLogging: doLogging);
    return reader.readRootDataset();
  }

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readTypedData(TypedData td,
      {Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    assert(td is Uint8List || td is ByteData);
    final bytes =
        new Bytes.typedDataView(td, td.offsetInBytes, td.lengthInBytes, endian);
    return ByteReader.readBytes(bytes, dParams: dParams, doLogging: doLogging);
  }

  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(File file,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    checkFile(file);
    final Uint8List td = file.readAsBytesSync();
    return ByteReader.readTypedData(td,
        endian: endian, dParams: dParams, doLogging: doLogging);
  }

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(String path,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    checkPath(path);
    return ByteReader.readFile(new File(path),
        doAsync: doAsync,
        endian: endian,
        dParams: dParams,
        doLogging: doLogging);
  }
}
/* TODO: later
  static Future<Uint8List> _readAsync(File file) async =>
      await file.readAsBytes();
*/
