// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/bytes/buffer/read_buffer.dart';
import 'package:convert/src/dicom/tag/reader/evr_tag_reader.dart';
import 'package:convert/src/dicom/tag/reader/ivr_tag_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// Creates a new [TagReader], which is decoder for Binary DICOM
/// (application/dicom).
class TagReader {
  final ByteData bd;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  final TagRootDataset rds;
  final EvrTagReader _evrReader;

  /// Creates a new [TagReader].
  TagReader(this.bd,
      {TagRootDataset rds,
      this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats})
      : rds = (rds == null) ? new TagRootDataset.empty(path) : rds,
        _evrReader = (doLogging)
            ? new EvrLoggingTagReader(bd, rds,
                dParams: dParams, reUseBD: reUseBD)
            : new EvrTagReader(bd, rds, dParams: dParams, reUseBD: reUseBD);

  /// Creates a [TagReader] from the contents of the [bytes].
  factory TagReader.fromUint8List(Uint8List bytes,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final bd = bytes.buffer.asByteData();
    return new TagReader(bd, path: '', reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [TagReader] from the contents of the [input].
  factory TagReader.fromList(List<int> input,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final bytes = (input is Uint8List) ? input : new Uint8List.fromList(input);
    return new TagReader.fromUint8List(bytes,
        reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [TagReader] from the contents of the [file].
  factory TagReader.fromFile(File file,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = true,
      bool showStats = false}) {
    final Uint8List bytes =
        (async) ? file.readAsBytes() : file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new TagReader(bd,
        path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [TagReader] from the contents of the [File] at [path].
  factory TagReader.fromPath(String path,
          {bool async = true,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD: true,
          bool doLogging = true,
          bool showStats = false}) =>
      new TagReader.fromFile(new File(path),
          async: async,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  ReadBuffer get rb => _evrReader.rb;
  Uint8List get bytes => rb.asUint8List();
  ElementOffsets get offsets => _evrReader.offsets;

  bool isFmiRead = false;
  int readFmi() => _evrReader.readFmi();

  IvrTagReader __ivrReader;
  IvrTagReader get _ivrReader => __ivrReader ??= (doLogging)
      ? new IvrLoggingTagReader.from(_evrReader)
      : new IvrTagReader.from(_evrReader);

  TagRootDataset readRootDataset() {
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi();

    final ds = (_evrReader.rds.transferSyntax.isEvr)
        ? _evrReader.readRootDataset(fmiEnd)
        : _ivrReader.readRootDataset(fmiEnd);

    if (showStats) _evrReader.rds.summary;
    return ds;
  }

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    final reader = new TagReader.fromUint8List(bytes,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [File].
  static TagRootDataset readFile(File file,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = true,
      bool showStats = false}) {
    checkFile(file);
    final reader = new TagReader.fromFile(file,
        async: async,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [path] ([File] or URL).
  static TagRootDataset readPath(String path,
      {bool async = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    final reader = new TagReader.fromFile(new File(path),
        async: async,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }
}
