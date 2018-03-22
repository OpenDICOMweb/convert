// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/evr_reader.dart';
import 'package:convert/src/binary/bytes/reader/evr_bd_reader.dart';
import 'package:convert/src/binary/bytes/reader/ivr_bd_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class ByteReader {
  final ReadBuffer rb;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  final BDRootDataset rds;
  final EvrReader _evrReader;

  /// Creates a new [ByteReader], which is decoder for Binary
  /// DICOM (application/dicom).
  ByteReader(this.rb,
      // Urgent fix: rds is always null
      {this.rds,
      this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.doLogging = false,
      this.showStats = false})
      : _evrReader = (doLogging)
            ? new EvrLoggingByteReader(
                rb.bytes, new BDRootDataset.empty(path, rb.bytes),
                dParams: dParams, reUseBD: reUseBD)
            : new EvrByteReader(rb.bytes, new BDRootDataset.empty(path, rb.bytes),
                dParams: dParams, reUseBD: reUseBD);

  /// Creates a [ByteReader] from the contents of the [uint8List].
  factory ByteReader.fromBytes(Bytes bytes,
          {String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false,
          bool showStats = false}) =>
      new ByteReader(new ReadBuffer(bytes),
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a [ByteReader] from the contents of the [uint8List].
  factory ByteReader.fromTypedData(TypedData uint8List,
          {Endian endian = Endian.little,
          String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false,
          bool showStats = false}) =>
      new ByteReader(new ReadBuffer.fromTypedData(uint8List, endian),
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a [ByteReader] from the contents of the [input].
  factory ByteReader.fromList(List<int> input,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false,
          bool showStats = false}) =>
      new ByteReader(new ReadBuffer.fromList(input),
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a [ByteReader] from the contents of the [file].
  factory ByteReader.fromFile(File file,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = false,
      bool showStats = false}) {
    final Uint8List bytes =
        (doAsync) ? _readAsync(file) : file.readAsBytesSync();
    return new ByteReader(new ReadBuffer.fromTypedData(bytes),
        path: file.path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a [ByteReader] from the contents of the [File] at [path].
  factory ByteReader.fromPath(String path,
          {bool doAsync = false,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD: true,
          bool doLogging = false,
          bool showStats = false}) =>
      new ByteReader.fromFile(new File(path),
          doAsync: doAsync,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  Uint8List get uint8List => rb.asUint8List();
  ElementOffsets get offsets => _evrReader.offsets;

  bool isFmiRead = false;
  int readFmi(int eStart) => _evrReader.readFmi(eStart);

  IvrByteReader __ivrReader;
  IvrByteReader get _ivrReader => __ivrReader ??= (doLogging)
      ? new IvrLoggingByteReader.from(_evrReader)
      : new IvrByteReader.from(_evrReader);

  BDRootDataset readRootDataset() {
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi(0);

    final ds = (_evrReader.rds.transferSyntax.isEvr)
        ? _evrReader.readRootDataset(fmiEnd)
        : _ivrReader.readRootDataset(fmiEnd);

    if (showStats) _evrReader.  rds.summary;
    return ds;
  }

  /// Reads the [BDRootDataset] from a [Uint8List].
  static BDRootDataset readBytes(Bytes bytes,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false,
      bool showStats = false}) {
    final reader = new ByteReader.fromBytes(bytes,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [BDRootDataset] from a [Uint8List].
  static BDRootDataset readTypedData(TypedData bytes,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false,
      bool showStats = false}) {
    assert(bytes is Uint8List || bytes is Bytes);
    final reader = new ByteReader.fromTypedData(bytes,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [BDRootDataset] from a [File].
  static BDRootDataset readFile(File file,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = false,
      bool showStats = false}) {
    checkFile(file);
    final reader = new ByteReader.fromFile(file,
        doAsync: doAsync,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [BDRootDataset] from a [path] ([File] or URL).
  static BDRootDataset readPath(String path,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false,
      bool showStats = false}) {
    checkPath(path);
    final reader = new ByteReader.fromFile(new File(path),
        doAsync: doAsync,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  static Future<Uint8List> _readAsync(File file) async =>
      await file.readAsBytes();
}
