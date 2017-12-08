// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/byte/reader/byte_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/evr_byte_log_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/ivr_byte_log_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/io_utils.dart';

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class ByteLogReader {
  final EvrByteLogReader _evrReader;
  IvrByteLogReader _ivrReader;

  /// Creates a new [ByteLogReader], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteLogReader(ByteData bd,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : _evrReader = new EvrByteLogReader(bd, new RootDatasetByte(bd, path: path),
            path: path, dParams: dParams, reUseBD: reUseBD);

  /// Creates a [ByteLogReader] from the contents of the [file].
  factory ByteLogReader.fromFile(File file,
      {DecodingParameters dParams = DecodingParameters.kNoChange, bool reUseBD = true}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new ByteLogReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [EvrByteLogReader] from the contents of the [File] at [path].
  factory ByteLogReader.fromPath(String path,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true}) =>
      new ByteLogReader.fromFile(new File(path), dParams: dParams, reUseBD: reUseBD);

  bool isFmiRead = false;

  @override
  ByteData readFmi() {
    final fmiBD = _evrReader.readFmi();
    isFmiRead = true;
    return fmiBD;
  }

  @override
  RootDataset readRootDataset() {
    if (!isFmiRead) readFmi();

    if (_evrReader.rds.transferSyntax.isEvr) {
      return _evrReader.readRootDataset();
    } else {
      _ivrReader = new IvrByteLogReader.from(_evrReader);
      return _ivrReader.readRootDataset();
    }
  }

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool reUseBD = true,
      bool showStats = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      ElementOffsets offsets}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new ByteLogReader(bd, path: path, reUseBD: reUseBD, dParams: dParams);
    return reader.readRootDataset();
  }

  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(File file,
      {bool reUseBD: true,
      bool showStats = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    checkFile(file);
    return readBytes(file.readAsBytesSync(),
        path: file.path, reUseBD: reUseBD, showStats: showStats, dParams: dParams);
  }

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(String path,
      {bool reUseBD = true,
      bool showStats = false,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    checkPath(path);
    return readFile(new File(path),
        reUseBD: reUseBD, showStats: showStats, dParams: dParams);
  }
}
