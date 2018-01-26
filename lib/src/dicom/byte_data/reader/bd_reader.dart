// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/bytes/read_buffer/read_buffer.dart';
import 'package:convert/src/dicom/base/reader/evr_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/evr_bd_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/ivr_bd_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class BDReader {
  final ReadBuffer rb;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  final BDRootDataset rds;
  final EvrReader _evrReader;

  /// Creates a new [BDReader], which is decoder for Binary DICOM (application/dicom).
  factory BDReader(ByteData bd,
      {BDRootDataset rds,
      String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = false,
      bool doLogging = false,
      bool showStats = false}) {
    rds ??= new BDRootDataset(bd, path: path);
    return new BDReader._(new ReadBuffer(bd),
        rds: rds,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new [BDReader], which is decoder for Binary DICOM (application/dicom).
  BDReader._(this.rb,
      {this.rds,
      this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = false,
      this.doLogging = false,
      this.showStats = false})
      // Why is this failing
      : _evrReader = (doLogging)
            ? new EvrLoggingBDReader(rb.bd, new BDRootDataset(rb.bd, path: path),
                dParams: dParams, reUseBD: reUseBD)
            : new EvrBDReader(rb.bd, new BDRootDataset(rb.bd, path: path),
                dParams: dParams, reUseBD: reUseBD);

  /// Creates a [BDReader] from the contents of the [bytes].
  factory BDReader.fromBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final bd = bytes.buffer.asByteData();
    return new BDReader(bd,
        path: '',
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a [BDReader] from the contents of the [input].
  factory BDReader.fromList(List<int> input,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final bytes = (input is Uint8List) ? input : new Uint8List.fromList(input);
    return new BDReader.fromBytes(bytes,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a [BDReader] from the contents of the [file].
  factory BDReader.fromFile(File file,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = true,
      bool showStats = false}) {
    final Uint8List bytes =
        (doAsync) ? _readAsync(file) : file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new BDReader(bd,
        path: file.path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a [BDReader] from the contents of the [File] at [path].
  factory BDReader.fromPath(String path,
          {bool async = true,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD: true,
          bool doLogging = true,
          bool showStats = false}) =>
      new BDReader.fromFile(new File(path),
          doAsync: async,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  Uint8List get uint8List => rb.asUint8List();
  ElementOffsets get offsets => _evrReader.offsets;

  bool isFmiRead = false;
  int readFmi() => _evrReader.readFmi();

  IvrBDReader __ivrReader;
  IvrBDReader get _ivrReader => __ivrReader ??= (doLogging)
      ? new IvrLoggingBDReader.from(_evrReader)
      : new IvrBDReader.from(_evrReader);

  BDRootDataset readRootDataset() {
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi();

    final ds = (_evrReader.rds.transferSyntax.isEvr)
        ? _evrReader.readRootDataset(fmiEnd)
        : _ivrReader.readRootDataset(fmiEnd);

    if (showStats) _evrReader.rds.summary;
    return ds;
  }

  /// Reads the [BDRootDataset] from a [Uint8List].
  static BDRootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final reader = new BDReader.fromBytes(bytes,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [BDRootDataset] from a [File].
  static BDRootDataset readFile(File file,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = true,
      bool showStats = false}) {
    checkFile(file);
    final reader = new BDReader.fromFile(file,
        doAsync: async,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [BDRootDataset] from a [path] ([File] or URL).
  static BDRootDataset readPath(String path,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    final reader = new BDReader.fromFile(new File(path),
        doAsync: async,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  static Future<Uint8List> _readAsync(File file) async =>
      await file.readAsBytes();
}
