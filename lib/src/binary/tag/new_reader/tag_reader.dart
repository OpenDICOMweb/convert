// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/logging_subreader.dart';
import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/binary/tag/new_reader/logging_tag_reader.dart';
import 'package:convert/src/binary/tag/new_reader/tag_reader_mixin.dart';
//import 'package:convert/src/binary/tag/new_reader/tag_reader_mixin.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/parse_info.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [TagRootDataset].
class TagEvrReader extends EvrSubReader with TagReaderMixin {
  final Bytes bytes;
  @override
  final ReadBuffer rb;
  @override
  final TagRootDataset rds;

  /// Creates a new [TagEvrReader].
  factory TagEvrReader(Bytes bytes,
      [TagRootDataset rds,
      DecodingParameters dParams = DecodingParameters.kNoChange]) {
    rds ??= new TagRootDataset.empty();
    return new TagEvrReader._(dParams, rds, bytes);
  }

  TagEvrReader._(DecodingParameters dParams, RootDataset rds, this.bytes)
      : rds = rds,
        rb = new ReadBuffer(bytes),
        super(dParams, rds);

/*
  @override
  Item makeItem(Dataset parent,
      [SQ sequence, Map<int, Element> eMap, Bytes bd]) =>
      new TagItem(parent, sequence, eMap ?? <int, Element>{});
*/

}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [TagRootDataset].
class LoggingTagEvrReader extends TagEvrReader with LoggingSubReader {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

/*
  factory LoggingTagEvrReader(Bytes bytes,
      DecodingParameters dParams,
        ParseInfo pInfo,
        ElementOffsets offsets) {
    final rds = new TagRootDataset.empty();
    return new LoggingTagEvrReader._(bytes, rds, dParams, offsets, pInfo);
  }
*/

  LoggingTagEvrReader._(Bytes bytes, RootDataset rds,
      DecodingParameters dParams, ElementOffsets offsets, ParseInfo pInfo)
      : offsets = offsets ?? new ElementOffsets(),
        pInfo = pInfo ?? new ParseInfo(rds),
        super._(bytes, rds, dParams);
}

// ignore_for_file: avoid_positional_boolean_parameters

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class TagIvrReader extends IvrSubReader with TagReaderMixin {
  final Bytes bytes;
  @override
  final TagRootDataset rds;
  @override
  final DecodingParameters dParams;
  @override
  final ReadBuffer rb;

  TagIvrReader.from(TagEvrReader reader)
      : bytes = reader.bytes,
        rds = reader.rds,
        dParams = reader.dParams,
        rb = reader.rb,
        super(reader.rds) {
    print('rds: $rds');
  }
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [TagRootDataset].
class LoggingTagIvrReader extends TagIvrReader with LoggingReader {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  LoggingTagIvrReader.from(TagEvrReader reader,
      [ParseInfo pInfo, ElementOffsets offsets])
      : pInfo = pInfo ?? new ParseInfo(reader.rds),
        offsets = offsets ?? new ElementOffsets(),
        super.from(reader);
}

/// Creates a new [TagReader], which is decoder for Binary DICOM
/// (application/dicom).
class TagReader {
  final Bytes bytes;
  final Endian endian;
  final String path;
  final bool reUseBD;
  final DecodingParameters dParams;
  final bool doLogging;
  final TagRootDataset rds;
  final TagEvrReader evrReader;
  final ReadBuffer rb;

  /// Creates a new [TagReader].
  factory TagReader(Bytes bytes,
      {Endian endian = Endian.little,
      String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false}) {
    final rb = new ReadBuffer(bytes);
    final rds = new TagRootDataset.empty();
    return TagReader._(
        bytes, rb, endian, rds, path, dParams, reUseBD, doLogging);
  }

  /// Creates a new [TagReader].
  TagReader._(this.bytes, this.rb, this.endian, this.rds, this.path,
      this.dParams, this.reUseBD, this.doLogging)
      : evrReader = (doLogging)
            ? makeLoggingTagEvrReader(bytes, rds, dParams)
            : makeTagEvrReader(bytes, rds, dParams);

  /// Creates a [TagReader] from the contents of a [Uint8List].
  factory TagReader.fromTypedData(Bytes bytes,
          {Endian endian = Endian.little,
          String path = '',
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false}) =>
      new TagReader(bytes,
          endian: endian,
          path: path,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging);

  /// Creates a [TagReader] from the contents of the [input].
  factory TagReader.fromList(List<int> input,
          {Endian endian = Endian.little,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD = true,
          bool doLogging = false}) =>
      new TagReader(new Bytes.fromList(input, endian),
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging);

  /// Creates a [TagReader] from the contents of the [file].
  factory TagReader.fromFile(File file,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = false}) {
    final Uint8List uint8List =
        (doAsync) ? _readFileAsync(file) : file.readAsBytesSync();
    return new TagReader(new Bytes.fromTypedData(uint8List, endian),
        path: file.path,
        endian: endian,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging);
  }

  /// Creates a [TagReader] from the contents of the [File] at [path].
  factory TagReader.fromPath(String path,
          {bool doAsync = false,
          Endian endian = Endian.little,
          DecodingParameters dParams = DecodingParameters.kNoChange,
          bool reUseBD: true,
          bool doLogging = false}) =>
      new TagReader.fromFile(new File(path),
          doAsync: doAsync,
          endian: endian,
          dParams: dParams,
          reUseBD: reUseBD,
          doLogging: doLogging);

  Uint8List get uint8List => rb.asUint8List();

  bool isFmiRead = false;
  int readFmi() => evrReader.readFmi(rb.index);

  TagIvrReader __ivrReader;
  TagIvrReader get _ivrReader => __ivrReader ??= (doLogging)
      ? new LoggingTagIvrReader.from(evrReader)
      : new TagIvrReader.from(evrReader);

  ElementOffsets get offsets => evrReader.offsets;
  ParseInfo get pInfo => evrReader.pInfo;

  TagRootDataset readRootDataset() {
    var fmiEnd = -1;
    if (!isFmiRead) fmiEnd = readFmi();

    return (evrReader.rds.transferSyntax.isEvr)
        ? evrReader.readRootDataset(fmiEnd)
        : _ivrReader.readRootDataset(fmiEnd);
  }

  static LoggingTagEvrReader makeLoggingTagEvrReader(
      Bytes bytes, TagRootDataset rds, DecodingParameters dParams) {
    final pInfo = new ParseInfo(rds);
    final offsets = new ElementOffsets();
    return new LoggingTagEvrReader._(bytes, rds, dParams, offsets, pInfo);
  }

  static TagEvrReader makeTagEvrReader(
          Bytes bytes, TagRootDataset rds, DecodingParameters dParams) =>
      new TagEvrReader._(bytes, rds, dParams);

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readBytes(Bytes bytes,
      {String path = '',
      bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false}) {
    final reader = new TagReader(bytes,
        path: path,
        endian: endian,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [Uint8List].
  static RootDataset readTypedData(TypedData td,
      {String path = '',
      bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false}) {
    assert(td is Uint8List || td is ByteData);
    final bytes = new Bytes.fromTypedData(td, endian);
    final reader = new TagReader.fromTypedData(bytes,
        path: path,
        endian: endian,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [File].
  static TagRootDataset readFile(File file,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD: true,
      bool doLogging = false}) {
    checkFile(file);
    final reader = new TagReader.fromFile(file,
        doAsync: doAsync,
        endian: endian,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging);
    return reader.readRootDataset();
  }

  /// Reads the [TagRootDataset] from a [path] ([File] or URL).
  static TagRootDataset readPath(String path,
      {bool doAsync = false,
      Endian endian = Endian.little,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      bool doLogging = false}) {
    checkPath(path);
    final reader = new TagReader.fromFile(new File(path),
        doAsync: doAsync,
        endian: endian,
        dParams: dParams,
        reUseBD: reUseBD,
        doLogging: doLogging);
    return reader.readRootDataset();
  }
}

Future<Uint8List> _readFileAsync(File file) async => await file.readAsBytes();
