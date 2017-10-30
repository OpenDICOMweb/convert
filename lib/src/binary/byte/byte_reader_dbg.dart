// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:element/tag_element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class ByteReader extends DcmReader {

  /// Creates a new [ByteReader].
  ByteReader(ByteData bd,
      {String path = '',
      //TODO: make async work and be the default
      bool async = false,
      bool fast = true,
      bool fmiOnly = false,
      TransferSyntax targetTS,
      bool reUseBD = true,
      DecodingParameters dParams})
      : super(bd, new RootDatasetByte(new RDSBytes(bd), path: path),
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            reUseBD: reUseBD,
            dParams: dParams);

  /// Creates a [ByteReader] from the contents of the [file].
  factory ByteReader.fromFile(File file,
      {bool async: false,
      bool fast: true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new ByteReader(bd,
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        reUseBD: reUseBD,
        dParams: dParams);
  }

  /// Creates a [ByteReader] from the contents of the [File] at [path].
  factory ByteReader.fromPath(String path,
          {bool async: true,
          bool fast: true,
          bool fmiOnly = false,
          bool throwOnError = true,
          bool allowMissingFMI = false,
          TransferSyntax targetTS,
          bool reUseBD = true,
          DecodingParameters dParams}) =>
      new ByteReader.fromFile(new File(path),
          async: async, fast: fast, fmiOnly: fmiOnly, reUseBD: reUseBD, dParams: dParams);

  // **** DcmReaderInterface ****

/*  /// The current [Dataset] being read.  This changes as Sequences are reAD.
  @override
  Dataset get currentDS => _currentDS;*/

  @override
  ElementList get elements => currentDS.elements;

//  @override
  Element makeElement(EBytes eb, int vrIndex, [VFFragments fragments]) =>
      makeTagElementFromEBytes(eb, vrIndex, fragments);

  /// Returns a new ByteSequence.
//  @override
  SQ makeSequence(EBytes eb, Dataset parent, List<Item> items) =>
      new SQbyte.fromBytes(eb, parent, items);

//  @override
  RootDataset makeRootDataset(RDSBytes dsBytes, Dataset parent,
          [ElementList elements, String path]) =>
      new RootDatasetByte(dsBytes, elements: elements, path: path);

  /// Returns a new [ItemByte].
//  @override
  Item makeItem(Dataset parent, {ElementList elements, SQ sequence, DSBytes eb}) =>
      new ItemByte(parent);

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;
  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;
  // **** End DcmReaderInterface ****

  RootDatasetByte readFMI({bool checkPreamble = false, bool allowMissingPrefix = false}) {
    final hadFmi =
        dcmReadFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
    rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? rootDS : null;
  }

  /// Reads a [RootDatasetByte],and stores it in [rootDS],
  /// and returns it.

  RootDatasetByte readRootDataset() {
    final rds = readRoot();
    rootDS.dsBytes = new RDSBytes(rootBD);
    return rds;
  }

  void debugStart(Object o, String msg) {
    log.debug('$rbb $o $msg');
  }

  void debug(Object o, Level level) {
    log.debug('$rmm $o');
  }

  void debugEnd(Object o, Level level) {
    log.debug('$rbb $o');
  }

  //Urgent: flush or fix
  static Element makeTagElement(EBytes eb, int vrIndex, VFFragments fragments) =>
      makeTagElementFromEBytes(eb, vrIndex, fragments);

/*
  //Urgent: flush or fix
  static TagElement makeTagPixelData(Element e) {
    assert(e.code == kPixelData);
    print('makePixelData: ${e.info}');
    if (e.vr == VR.kOB)
      return new OBPixelData.fromBytes(e.tag, e.vfBytes, e.vfLength, e.fragments);
    if (e.vr == VR.kOW)
      return new OWPixelData.fromBytes(e.tag, e.vfBytes, e.vfLength, e.fragments);
    if (e.vr == VR.kOB)
      return new UNPixelData.fromBytes(e.tag, e.vfBytes, e.vfLength, e.fragments);
    print('makePixelData: ${e.info}');
    return invalidVRError(e.vr, 'TagReader.makePixelData');
  }
*/

  /// Reads only the File Meta Information (FMI), if present.
  static RootDatasetByte readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true}) {
    RootDatasetByte rds;
    try {
      final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
      final reader = new ByteReader(bd,
          path: path, async: async, fast: fast, fmiOnly: fmiOnly, reUseBD: reUseBD);
      rds = reader.readRootDataset();
    } on ShortFileError catch (e) {
      log.warn('Short File: $e');
    }
    return rds;
  }

  static RootDatasetByte readFile(File file,
      {bool async: true, bool fast = true, bool fmiOnly = false, bool reUseBD: true}) {
    checkFile(file);
    return readBytes(file.readAsBytesSync(),
        path: file.path, async: async, fast: fast, fmiOnly: fmiOnly, reUseBD: reUseBD);
  }

  static Dataset readPath(String path,
      {bool async: true, bool fast = true, bool fmiOnly = false, bool reUseBD = true}) {
    checkPath(path);
    return readFile(new File(path), async: async, fast: fast, fmiOnly: fmiOnly);
  }

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readFileFmiOnly(File file,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool reUseBD = true}) =>
      readFile(file, async: async, fast: fast, fmiOnly: true, reUseBD: reUseBD);

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readPathFmiOnly(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool throwOnError = true,
          TransferSyntax targetTS,
          bool reUseBD = true}) =>
      readPath(path, async: async, fast: fast, fmiOnly: true, reUseBD: reUseBD);
}
