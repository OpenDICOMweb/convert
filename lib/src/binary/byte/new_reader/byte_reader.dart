// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/byte/new_reader/byte_subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class ByteReader {
  final Bytes bytes;
  final ReadBuffer rb;
  final EvrSubReader evrReader;
  IvrSubReader _ivrReader;
  int fmiEnd;

  /// Creates a new [ByteReader], which is decoder for Binary
  /// DICOM (application/dicom).
  factory ByteReader(Bytes bytes,
  {DecodingParameters dParams = DecodingParameters.kNoChange,
    bool doLogging = false}) {
    final rb = new ReadBuffer(bytes);
    final rds = new BDRootDataset.empty();
    return ByteReader._(dParams, rds, rb, bytes, doLogging);
  }

  ByteReader._(DecodingParameters dParams, BDRootDataset rds, this.rb,
      this.bytes, bool doLogging)
      : evrReader =  (doLogging)
      ? new LoggingByteEvrSubReader(dParams, rds, rb)
      : new ByteEvrSubReader(dParams, rds, rb);

  DecodingParameters get dParams => evrReader.dParams;
  BDRootDataset get rds => evrReader.rds;
  Uint8List get uint8List => rb.asUint8List();

  bool isFmiRead = false;
  int readFmi(int eStart) => evrReader.readFmi(eStart);

  ByteIvrSubReader __ivrReader;
  ByteIvrSubReader get ivrReader =>
      __ivrReader ??= new ByteIvrSubReader.from(evrReader);

  RootDataset readRootDataset([int fmiEnd]) {
    if (!isFmiRead) fmiEnd ??= readFmi(0);
    return (evrReader.rds.transferSyntax.isEvr)
        ? evrReader.readRootDataset(fmiEnd)
        : _ivrReader.readRootDataset(fmiEnd);
  }

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Bytes bytes,
      {DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final reader = new ByteReader(bytes, dParams: dParams);
    return reader.readRootDataset();
  }
  
  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readTypedData(TypedData td,
      {Endian endian = Endian.little,
        DecodingParameters dParams = DecodingParameters.kNoChange}) {
    assert(td is Uint8List || td is ByteData);
    final bytes = new Bytes.fromTypedData(td, endian);
    return ByteReader.readBytes(bytes, dParams: dParams);
  }

  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(File file,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    checkFile(file);
    final Uint8List td = file.readAsBytesSync();
    return ByteReader.readTypedData(td, dParams: dParams);
  }

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(String path,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    checkPath(path);
    return ByteReader.readFile(new File(path),
        doAsync: doAsync,
        dParams: dParams);
  }

/* TODO: later
  static Future<Uint8List> _readAsync(File file) async =>
      await file.readAsBytes();
*/

}

