// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/evr_bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/evr_logging_bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/ivr_bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/reader/ivr_logging_bd_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/io_utils.dart';

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
  IvrReaderBD _ivrReader;

  /// Creates a new [BDReader], which is decoder for Binary DICOM
  /// (application/dicom).
  factory BDReader(ByteData bd,
          {String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = true,
          bool showStats = true}) =>
      new BDReader._(bd, new BDRootDataset(bd, path: path),
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a new [BDReader], which is decoder for Binary DICOM
  /// (application/dicom).
  BDReader._(this.bd, this.rds,
      {this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats})
      : _evrReader = (doLogging)
            ? new EvrLogReaderBD(bd, rds,
                path: path, dParams: dParams, reUseBD: reUseBD)
            : new EvrReaderBD(bd, new BDRootDataset(bd, path: path),
                path: path, dParams: dParams, reUseBD: reUseBD);

  /// Creates a [BDReader] from the contents of the [file].
  factory BDReader.fromFile(File file,
      {DecodingParameters dParams = DecodingParameters.kNoChange, bool reUseBD = true}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new BDReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [EvrReaderBD] from the contents of the [File] at [path].
  factory BDReader.fromPath(String path,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true}) =>
      new BDReader.fromFile(new File(path), dParams: dParams, reUseBD: reUseBD);

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
          ? new IvrLogReaderBD.from(_evrReader)
          : new IvrReaderBD.from(_evrReader);
      ds = _ivrReader.readRootDataset(fmiEnd);
    }
    if (showStats) _evrReader.rds.summary;
    return ds;
  }

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(
    Uint8List bytes, {
    String path = '',
    DecodingParameters dParams = DecodingParameters.kNoChange,
    bool reUseBD = true,
    bool doLogging = true,
    bool showStats = false,
  }) {
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
    DecodingParameters dParams = DecodingParameters.kNoChange,
    bool reUseBD: true,
    bool doLogging = true,
    bool showStats = false,
  }) {
    checkFile(file);
    return readBytes(file.readAsBytesSync(),
        path: file.path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(
    String path, {
    DecodingParameters dParams = DecodingParameters.kNoChange,
    bool reUseBD = true,
    bool doLogging = true,
    bool showStats = false,
  }) {
    checkPath(path);
    return readFile(new File(path),
        dParams: dParams, reUseBD: reUseBD, doLogging: doLogging, showStats: showStats);
  }
}
