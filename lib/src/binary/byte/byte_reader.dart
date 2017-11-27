// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';
import 'package:dcm_convert/src/binary/base/reader/base/evr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/base/ivr_reader.dart';
import 'package:dcm_convert/src/binary/base/reader/base/reader_base.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/io_utils.dart';
import 'package:element/byte_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';

/// Returns a new ByteSequence.
SQ _makeSequence(EBytes eb, Dataset parent, List<Item> items) =>
    new SQbyte.fromBytes(eb, parent, items);

RootDataset makeRootDataset(RDSBytes dsBytes, Dataset parent,
        [ElementList elements, String path]) =>
    new RootDatasetByte(dsBytes, elements: elements, path: path);

/// Returns a new [ItemByte].
Item _makeItem(Dataset parent, {ElementList elements, SQ sequence, DSBytes eb}) =>
    new ItemByte(parent);

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class ByteReader extends EvrReader {
  /// Creates a new [ByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteReader(ByteData bd,
      {String path = '',
      bool fast = true,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets})
      : super(bd, new RootDatasetByte(new RDSBytes(bd), path: path),
            path, dParams, reUseBD: reUseBD) {
    eMaker = makeBEFromEBytes;
    pixelDataMaker = makeBEPixelDataFromEBytes;
    sequenceMaker = _makeSequence;
    itemMaker = _makeItem;
  }

  /// Creates a [ByteReader] from the contents of the [file].
  factory ByteReader.fromFile(File file,
      {bool reUseBD = true, DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new ByteReader(bd, path: file.path, reUseBD: reUseBD, dParams: dParams);
  }

  /// Creates a [ByteReader] from the contents of the [File] at [path].
  factory ByteReader.fromPath(String path,
          {bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      new ByteReader.fromFile(new File(path), reUseBD: reUseBD, dParams: dParams);

  @override
  RootDataset read() {
     readFmi();
    if (rds.transferSyntax.isEvr) {
      evrRead();
    } else {
      final ivrReader = new IvrReader(bd, rds,  path: path, dParams:  dParams, reUseBD: reUseBD);
      ivrRead();
      return rds;
    }
  }
  @override
  ElementList get elements => cds.elements;

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
    final reader = new ByteReader(bd,
        path: path, reUseBD: reUseBD, dParams: dParams);
    return reader.read();
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