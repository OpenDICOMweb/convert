// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/reader.dart';
import 'package:convert/src/binary/base/new_reader/log_reader.dart';
import 'package:convert/src/binary/bytes/new_reader/bytes_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/io_utils.dart';

class ByteEvrReader extends EvrReader with ByteReaderMixin {
  Bytes bytes;
  @override
  BDRootDataset rds;
  @override
  DecodingParameters dParams;
  @override
  ReadBuffer rb;

  factory ByteEvrReader(Bytes bytes,
      [BDRootDataset rds,
      DecodingParameters dParams = DecodingParameters.kNoChange]) {
    rds ??= new BDRootDataset.empty();
    return new ByteEvrReader._(bytes, rds, dParams);
  }

  ByteEvrReader._(this.bytes, this.rds, this.dParams)
      : rb = new ReadBuffer(bytes),
        super(rds);
}

class LoggingByteEvrReader extends ByteEvrReader with LoggingReader {
  factory LoggingByteEvrReader(Bytes bytes,
      [BDRootDataset rds,
      DecodingParameters dParams = DecodingParameters.kNoChange]) {
    rds ??= new BDRootDataset.empty();
    return new LoggingByteEvrReader._(bytes, rds, dParams);
  }

  LoggingByteEvrReader._(
      Bytes bytes, RootDataset rds, DecodingParameters dParams)
      : super._(bytes, rds, dParams);
}

class ByteIvrReader extends IvrReader with ByteReaderMixin {
  Bytes bytes;
  @override
  ReadBuffer rb;
  @override
  BDRootDataset rds;
  @override
  DecodingParameters dParams;

  ByteIvrReader.from(ByteEvrReader reader)
      : bytes = reader.bytes,
        rb = reader.rb,
        rds = reader.rds,
        dParams = reader.dParams,
        super(reader.rds);
}

class LoggingByteIvrReader extends ByteIvrReader with LoggingReader {
  LoggingByteIvrReader.from(ByteEvrReader reader) : super.from(reader);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class ByteReader extends Object with ByteReaderMixin {
  final ReadBuffer rb;
  // TODO: Decide about removing path
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  @override
  final BDRootDataset rds;
  final EvrReader evrReader;
  //Dataset cds;
  IvrReader _ivrReader;

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
      : evrReader = (doLogging)
            ? new LoggingByteEvrReader(
                rb.bytes, new BDRootDataset.empty(path, rb.bytes), dParams)
            : new ByteEvrReader(
                rb.bytes, new BDRootDataset.empty(path, rb.bytes), dParams);

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
  ElementOffsets get offsets => evrReader.offsets;

  bool isFmiRead = false;
  int readFmi(int eStart) => evrReader.readFmi(eStart);

  ByteIvrReader __ivrReader;
  ByteIvrReader get ivrReader => __ivrReader ??= (doLogging)
      ? new LoggingByteIvrReader.from(evrReader)
      : new ByteIvrReader.from(evrReader);

  BDRootDataset readRootDataset() {
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi(0);

    final ds = (evrReader.rds.transferSyntax.isEvr)
        ? evrReader.readRootDataset(fmiEnd)
        : _ivrReader.readRootDataset(fmiEnd);

    if (showStats) evrReader.rds.summary;
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
