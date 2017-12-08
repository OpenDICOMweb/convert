// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';

import 'package:dcm_convert/src/binary/base/reader/debug/log_evr_reader.dart';
import 'package:dcm_convert/src/binary/byte/reader/evr_byte_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/io_utils.dart';
import 'package:element/byte_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class LogEvrByteReader extends LogEvrReader {
  @override
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  /// Creates a new [EvrByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  factory LogEvrByteReader(ByteData bd,
      {String path = '',
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true,
      Element offsets}) {
    final rds = new RootDatasetByte(new RDSBytes(bd), path: path);
    return new LogEvrByteReader._(bd, rds, path, dParams, reUseBD);
  }

  LogEvrByteReader._(ByteData bd, RootDatasetByte rds, String path,
      DecodingParameters dParams, bool reUseBD)
      : offsets = new ElementOffsets(),
        pInfo = new ParseInfo(rds),
        super(bd, rds, path, dParams, reUseBD);

  /// Creates a [EvrByteReader] from the contents of the [file].
  factory LogEvrByteReader.fromFile(File file,
      {bool reUseBD = true, DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new LogEvrByteReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [EvrByteReader] from the contents of the [File] at [path].
  factory LogEvrByteReader.fromPath(String path,
          {bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      new LogEvrByteReader.fromFile(new File(path), reUseBD: reUseBD, dParams: dParams);

  @override
  ElementList get elements => cds.elements;

  @override
  Element makeElement(int code, int vrIndex, EBytes eb) => makeBEFromEBytes(eb, vrIndex);

  @override
  Element makePixelData(int code, int vrIndex, EBytes eb, {VFFragments fragments}) =>
      makeBEPixelDataFromEBytes(eb, vrIndex);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, EBytes eb, Dataset parent, List<Item> items) =>
      new SQbyte.fromBytes(eb, parent, items);

  @override
  RootDataset makeRootDataset(RDSBytes dsBytes, [ElementList elements, String path]) =>
      new RootDatasetByte(dsBytes, elements: elements, path: path);

  /// Returns a new [ItemByte].
  @override
  Item makeItem(Dataset parent, {IDSBytes eb, ElementList elements, SQ sequence}) =>
      new ItemByte(parent, eb);

  // **** DcmReaderInterface ****

  //Urgent: flush or fix
  static Element makeTagElement(EBytes eb, [int vrIndex]) =>
      makeBEFromEBytes(eb, vrIndex);

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool reUseBD = true,
      bool showStats = false,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new EvrByteReader(bd, path: path, reUseBD: reUseBD, dParams: dParams);
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

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readFileFmiOnly(File file,
          {TransferSyntax targetTS,
          bool reUseBD = true,
          bool showStats = false,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readFile(file, reUseBD: reUseBD, dParams: dParams);

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readPathFmiOnly(String path,
          {bool reUseBD = true,
          bool showStats = false,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readPath(path, reUseBD: reUseBD, showStats: showStats, dParams: dParams);
}
