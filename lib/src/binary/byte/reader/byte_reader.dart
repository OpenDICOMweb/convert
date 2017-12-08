// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/byte/reader/evr_byte_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/ivr_byte_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class ByteReader {
  final ByteData bd;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final EvrByteReader evrReader;
  IvrByteReader _ivrReader;

  /// Creates a new [ByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteReader(this.bd,
      {this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true})
  : evrReader = new EvrByteReader(bd, path: path, dParams: dParams, reUseBD: reUseBD);

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
      new ByteReader.fromFile(new File(path), dParams: dParams,reUseBD: reUseBD);

  bool isFmiRead = false;

  ByteData readFmi() {
    final fmiBD = evrReader.readFmi();
    isFmiRead = true;
    return fmiBD;
  }

  RootDataset readRootDataset() {
    if (!isFmiRead) readFmi();

    if (evrReader.rds.transferSyntax.isEvr) {
      return evrReader.readRootDataset();
    } else {
      _ivrReader = new IvrByteReader(bd, path: path, dParams: dParams, reUseBD: reUseBD);
      return _ivrReader.readRootDataset();
    }
  }

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool reUseBD = true,
      bool showStats = false,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new ByteReader(bd, path: path, reUseBD: reUseBD, dParams: dParams);
    return reader.readRootDataset();
  }

  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(File file,
      {bool reUseBD: true,
      bool showStats = false,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    checkFile(file);
    return readBytes(file.readAsBytesSync(),
        path: file.path, reUseBD: reUseBD, showStats: showStats, dParams: dParams);
  }

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(String path,
      {bool async: true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      bool showStats = false,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    checkPath(path);
    return readFile(new File(path),
        reUseBD: reUseBD, showStats: showStats, dParams: dParams);
  }
}
