// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/tag/reader/evr_tag_reader.dart';
import 'package:convert/src/binary/tag/reader/ivr_tag_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// Creates a new [TagReader], which is decoder for Binary DICOM
/// (application/dicom).
class TagReader {
  final ReadBuffer rb;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final bool showStats;
  final TagRootDataset rds;
  final EvrTagReader _evrReader;

  /// Creates a new [TagReader].
  TagReader(this.rb,
      {this.rds,
      this.path = '',
      this.dParams = DecodingParameters.kNoChange,
      this.reUseBD = true,
      this.doLogging = false,
      this.showStats = false})
      : _evrReader = (doLogging)
            ? new EvrLoggingTagReader(
                rb.bd, new TagRootDataset.empty(path, rb.bd),
                dParams: dParams, reUseBD: reUseBD)
            : new EvrTagReader(rb.bd, new TagRootDataset.empty(path, rb.bd),
                dParams: dParams, reUseBD: reUseBD);

  /// Creates a [TagReader] from the contents of the [bytes].
  factory TagReader.fromBytes(Bytes bytes,
          {String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = true,
          bool showStats = false}) =>
      new TagReader(new ReadBuffer.fromBytes(bytes),
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a [TagReader] from the contents of a [Uint8List].
  factory TagReader.fromTypedData(TypedData uint8List,
          {Endian endian = Endian.little,
          String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false,
          bool showStats = false}) =>
      new TagReader(new ReadBuffer.fromTypedData(uint8List, endian),
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a [TagReader] from the contents of the [input].
  factory TagReader.fromList(List<int> input,
          {DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false,
          bool showStats = false}) =>
      new TagReader(new ReadBuffer.fromList(input),
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  /// Creates a [TagReader] from the contents of the [file].
  factory TagReader.fromFile(File file,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = false,
      bool showStats = false}) {
    final Uint8List bytes =
        (doAsync) ? _readFileAsync(file)  : file.readAsBytesSync();
    return new TagReader(new ReadBuffer.fromTypedData(bytes),
        path: file.path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a [TagReader] from the contents of the [File] at [path].
  factory TagReader.fromPath(String path,
          {bool doAsync = false,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD: true,
          bool doLogging = false,
          bool showStats = false}) =>
      new TagReader.fromFile(new File(path),
          doAsync: doAsync,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging,
          showStats: showStats);

  Uint8List get uint8List => rb.asUint8List();
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
  static RootDataset readBytes(Bytes bytes,
      {String path = '',
      bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false,
      bool showStats = false}) {
    final reader = new TagReader.fromBytes(bytes,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readTypedData(TypedData bytes,
      {String path = '',
      bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false,
      bool showStats = false}) {
    assert(bytes is Uint8List || bytes is ByteData);
    final reader = new TagReader.fromTypedData(bytes,
        path: path,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [File].
  static TagRootDataset readFile(File file,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = false,
      bool showStats = false}) {
    checkFile(file);
    final reader = new TagReader.fromFile(file,
        doAsync: doAsync,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [path] ([File] or URL).
  static TagRootDataset readPath(String path,
      {bool doAsync = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false,
      bool showStats = false}) {
    checkPath(path);
    final reader = new TagReader.fromFile(new File(path),
        doAsync: doAsync,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return reader.readRootDataset();
  }
}

Future<Uint8List> _readFileAsync(File file) async =>
await file.readAsBytes();


