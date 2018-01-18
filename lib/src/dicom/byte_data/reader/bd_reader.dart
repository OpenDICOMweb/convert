// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/read_buffer.dart';
import 'package:convert/src/dicom/base/reader/evr_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/evr_bd_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/evr_logging_bd_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/ivr_bd_reader.dart';
import 'package:convert/src/dicom/byte_data/reader/ivr_logging_bd_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class BDReader {
  final ByteData bd;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  final BDRootDataset rds;
  final EvrReader _evrReader;
  IvrBDReader _ivrReader;

  /// Creates a new [BDReader], which is decoder for Binary DICOM (application/dicom).
  BDReader(this.bd,
      {BDRootDataset rds,
      this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats})
      : rds = (rds == null) ? new BDRootDataset(bd, path: path) : rds,
        _evrReader = (doLogging)
            ? new EvrLoggingBDReader(bd, rds, dParams: dParams, reUseBD: reUseBD)
            : new EvrBDReader(bd, new BDRootDataset(bd, path: path),
                 dParams: dParams, reUseBD: reUseBD);

  /// Creates a [BDReader] from the contents of the [bytes].
  factory BDReader.fromBytes(Uint8List bytes,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true}) {
    final bd = bytes.buffer.asByteData();
    return new BDReader(bd, path: '', reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [BDReader] from the contents of the [input].
  factory BDReader.fromList(List<int> input,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true}) {
    final bytes = (input is Uint8List) ? input : new Uint8List.fromList(input);
    return new BDReader.fromBytes(bytes, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [BDReader] from the contents of the [file].
  factory BDReader.fromFile(File file,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true}) {
    final Uint8List bytes = (async) ? file.readAsBytes() : file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new BDReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [EvrBDReader] from the contents of the [File] at [path].
  factory BDReader.fromPath(String path,
          {bool async = true,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true}) =>
      new BDReader.fromFile(new File(path),
          async: async, dParams: dParams, reUseBD: reUseBD);

  bool isFmiRead = false;

  ReadBuffer get rb => _evrReader.rb;
  Uint8List get bytes => rb.bytes;
  ElementOffsets get offsets => _evrReader.offsets;

  int readFmi() => _evrReader.readFmi();

  RootDataset readRootDataset() {
    BDRootDataset ds;
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi();

    if (_evrReader.rds.transferSyntax.isEvr) {
      ds = _evrReader.readRootDataset(fmiEnd);
    } else {
      _ivrReader = (doLogging)
          ? new IvrLoggingBDReader.from(_evrReader)
          : new IvrBDReader.from(_evrReader);
      ds = _ivrReader.readRootDataset(fmiEnd);
    }
    if (showStats) _evrReader.rds.summary;
    return ds;
  }

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new BDReader(bd,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(
    File file, {
    bool async = true,
    DecodingParameters dParams = DecodingParameters.kNoChange,
    bool reUseBD: true,
    bool doLogging = true,
    bool showStats = false,
  }) {
    checkFile(file);
    return readBytes(file.readAsBytesSync(),
        path: file.path,
        async: async,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(
    String path, {
    bool async = true,
    DecodingParameters dParams = DecodingParameters.kNoChange,
    bool reUseBD = true,
    bool doLogging = true,
    bool showStats = false,
  }) {
    checkPath(path);
    return readFile(new File(path),
        async: async,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }
}
