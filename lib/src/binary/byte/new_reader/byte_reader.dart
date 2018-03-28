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
import 'package:convert/src/binary/byte/new_reader/byte_subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

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
      new ByteReader.fromBytes(new Bytes.fromTypedData(bList),
          dParams: dParams, doLogging: doLogging);

  /// Creates a new [ByteReader].
  ByteReader.fromBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false})
      : evrSubReader =
            //  ? new LoggingByteEvrSubReader(bytes, dParams)
            new ByteEvrSubReader(bytes, dParams, doLogging: doLogging),
        super(bytes, doLogging: doLogging);

  factory ByteReader.fromFile(File f,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final bList = f.readAsBytesSync();
    return new ByteReader.fromBytes(bList,
        dParams: dParams, doLogging: doLogging);
  }

  factory ByteReader.fromPath(String path,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool doLogging = false}) {
    final f = new File(path);
    return ByteReader.fromFile(f, dParams: dParams, doLogging: doLogging);
  }

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
    final bytes = new Bytes.fromTypedData(td, endian);
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
