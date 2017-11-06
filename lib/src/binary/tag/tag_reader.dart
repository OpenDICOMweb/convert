// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/tag_dataset.dart';
import 'package:element/tag_element.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

/// Returns a new ByteSequence.
//  @override
SQ _makeSequence(EBytes eb, Dataset parent, List<Item> items) =>
		new SQtag.fromBytes(eb, parent, items);

/// Returns a new [ItemByte].
Item _makeItem(Dataset parent, {ElementList elements, SQ sequence, DSBytes eb}) =>
		new ItemTag(parent);

/// Creates a new [TagReader], which is decoder for Binary DICOM
/// (application/dicom).
class TagReader extends DcmReader {

  /// Creates a new [TagReader].
  TagReader(ByteData bd,
      {String path = '',
      bool async: true,
      bool fast: true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange})
      : super(bd, new RootDatasetTag(dsBytes: new RDSBytes(bd), path: path),
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            reUseBD: reUseBD,
            dParams: dParams) {
	  elementMaker = makeTagElementFromEBytes;
	  sequenceMaker = _makeSequence;
	  itemMaker = _makeItem;
  }

  /// Creates a [TagReader] from the contents of the [file].
  factory TagReader.fromFile(File file,
      {bool async: false,
      bool fast: true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new TagReader(bd,
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        reUseBD: reUseBD,
        dParams: dParams);
  }

  /// Creates a [TagReader] from the contents of the [File] at [path].
  factory TagReader.fromPath(String path,
          {bool async: true,
          bool fast: true,
          bool fmiOnly = false,
          bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      new TagReader.fromFile(new File(path),
          async: async, fast: fast, fmiOnly: fmiOnly, reUseBD: reUseBD, dParams: dParams);

  @override
  ElementList get elements => currentDS.elements;

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;

  // TODO: add Async argument and make it the default
  /// Reads only the File Meta Information (FMI), if present.
  static RootDatasetTag readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new TagReader(bd,
        path: path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        reUseBD: reUseBD,
        dParams: dParams);
    final root = reader.read(dParams);
    log.debug(root);
    return root;
  }

  static RootDatasetTag readFile(File file,
      {bool async: true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseDB = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, async: async, fast: fast, fmiOnly: fmiOnly, dParams: dParams);
  }

  static RootDatasetTag readPath(String path,
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
