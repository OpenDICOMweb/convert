// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/binary/base/reader/evr_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/evr_byte_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/evr_byte_log_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/ivr_byte_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/ivr_byte_log_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class ByteReader {
  final ByteData bd;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  final RootDatasetByte rds;
  final EvrReader _evrReader;
  IvrByteReader _ivrReader;

  /// Creates a new [ByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  factory ByteReader(ByteData bd,
          {String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = true,
          bool showStats = true}) =>
      new ByteReader._(bd, new RootDatasetByte(bd, path: path),
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a new [ByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteReader._(this.bd, this.rds,
      {this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats})
      : _evrReader = (doLogging)
            ? new EvrByteLogReader(bd, rds,
                path: path, dParams: dParams, reUseBD: reUseBD)
            : new EvrByteReader(bd, new RootDatasetByte(bd, path: path),
                path: path, dParams: dParams, reUseBD: reUseBD) {
    print('EvrReader: $rds');
  }

  /// Creates a [ByteReader] from the contents of the [file].
  factory ByteReader.fromFile(File file,
      {DecodingParameters dParams = DecodingParameters.kNoChange, bool reUseBD = true}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new ByteReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [EvrByteReader] from the contents of the [File] at [path].
  factory ByteReader.fromPath(String path,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true}) =>
      new ByteReader.fromFile(new File(path), dParams: dParams, reUseBD: reUseBD);

  bool isFmiRead = false;

  ReadBuffer get rb => _evrReader.rb;
  Uint8List get bytes => rb.bytes;
  ElementOffsets get offsets => _evrReader.offsets;

  ByteData readFmi() => _evrReader.readFmi();

  RootDataset readRootDataset() {
    RootDatasetByte ds;
    if (!isFmiRead) readFmi();

    if (_evrReader.rds.transferSyntax.isEvr) {
      ds = _evrReader.readRootDataset();
    } else {
      _ivrReader = (doLogging)
          ? new IvrByteLogReader.from(_evrReader)
          : new IvrByteReader.from(_evrReader);
      ds = _ivrReader.readRootDataset();
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
    final reader = new ByteReader(bd,
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
