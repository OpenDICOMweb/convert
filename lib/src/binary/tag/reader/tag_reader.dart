// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';


import 'package:core/core.dart';

import 'package:dcm_convert/src/binary/tag/reader/evr_tag_reader.dart';
import 'package:dcm_convert/src/binary/tag/reader/ivr_tag_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';

/// Creates a new [TagReader], which is decoder for Binary DICOM
/// (application/dicom).
class TagReader {
  final ByteData bd;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final ElementOffsets offsets;
  final EvrTagReader _evrReader;

  IvrTagReader _ivrReader;

  /// Creates a new [TagReader].
  TagReader(this.bd,
      {this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.offsets})
      : _evrReader = new EvrTagReader(bd, new TagRootDataset(bd: bd, path: path),
                                          path:
  path, dParams:
  dParams, reUseBD: reUseBD);

  /// Creates a [TagReader] from the contents of the [file].
  factory TagReader.fromFile(File file,
      {DecodingParameters dParams = DecodingParameters.kNoChange, bool reUseBD = true}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new TagReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [TagReader] from the contents of the [File] at [path].
  factory TagReader.fromPath(String path,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true}) =>
      new TagReader.fromFile(new File(path), dParams: dParams, reUseBD: reUseBD);

  bool isFmiRead = false;

  int readFmi() {
    final fmiEnd = _evrReader.readFmi();
    isFmiRead = true;
    return fmiEnd;
  }

  RootDataset readRootDataset() {
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi();
    if (_evrReader.rds.transferSyntax.isEvr) {
      return _evrReader.readRootDataset(fmiEnd);
    } else {
      _ivrReader = new IvrTagReader.from(_evrReader);
      return _ivrReader.readRootDataset(fmiEnd);
    }
  }

  // TODO: add Async argument and make it the default
  /// Reads only the File Meta Information (FMI), if present.
  static TagRootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new TagReader(bd, path: path, reUseBD: reUseBD, dParams: dParams);
    final rds = reader.readRootDataset();
    log.debug(rds);
    return rds;
  }

  static TagRootDataset readFile(File file,
      {bool async: true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseDB = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, async: async, fast: fast, fmiOnly: fmiOnly, dParams: dParams);
  }

  static TagRootDataset readPath(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readFile(new File(path),
          async: async, fast: fast, fmiOnly: fmiOnly, reUseDB: true, dParams: dParams);

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readFileFmiOnly(File file,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readFile(file,
          async: async, fast: fast, fmiOnly: true, reUseDB: reUseBD, dParams: dParams);

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readPathFmiOnly(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readPath(path,
          async: async, fast: fast, fmiOnly: true, reUseBD: reUseBD, dParams: dParams);
}
