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

import 'package:dcm_convert/src/binary/reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDatasetByte].
class ByteReader extends DcmReader {
  @override
  final RootDataset<int> rootDS;
  Dataset _currentDS;

  /// Creates a new [ByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteReader(ByteData bd,
      {String path = '',
      //TODO: make async work and be the default
      bool async = false,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters decode = DecodingParameters.kNoChange})
      : rootDS = new RootDatasetByte(new RDSBytes(bd), path: path),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            reUseBD: reUseBD,
            dParams: decode);

  /// Creates a [ByteReader] from the contents of the [file].
  factory ByteReader.fromFile(File file,
      {bool async: false,
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    final Uint8List bytes = file.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    return new ByteReader(bd,
        path: file.path, async: async, fast: fast, fmiOnly: fmiOnly, reUseBD: reUseBD);
  }

  /// Creates a [ByteReader] from the contents of the [File] at [path].
  factory ByteReader.fromPath(String path,
          {bool async: true,
          bool fast: true,
          bool fmiOnly = false,
          bool throwOnError = true,
          bool allowMissingFMI = false,
          TransferSyntax targetTS,
          bool reUseBD = true}) =>
      new ByteReader.fromFile(new File(path),
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          throwOnError: throwOnError,
          allowMissingFMI: allowMissingFMI,
          targetTS: targetTS,
          reUseBD: reUseBD);

  // **** DcmReaderInterface ****

  /// The current [Dataset] being read.  This changes as Sequences are reAD.
  @override
  Dataset get currentDS => _currentDS;
  // @override
  // set currentDS(Dataset ds) => _currentDS = ds;

  @override
  ElementList get elements => currentDS.elements;

  @override
  Element makeElement(EBytes eb, int vrIndex, [VFFragments fragments]) =>
      makeFromEBytes(eb, vrIndex, fragments);

  @override
  SQ makeSequence(EBytes eb, Dataset parent, List<Item> items) =>
      new SQbyte.fromBytes(eb, parent, items);

  @override
  RootDataset makeRootDataset(RDSBytes dsBytes, Dataset parent,
          [ElementList elements, String path]) =>
      new RootDatasetByte(dsBytes, elements: elements, path: path);

  /// Returns a new [ItemByte].
//  @override
//  Item makeItem(Dataset parent, {ElementList elements, SQ sequence, DSBytes eb}) {}

  /// Returns a new [ItemByte].
  @override
  Item makeItem(Dataset parent, {ElementList elements, SQ sequence, DSBytes eb}) =>
      new ItemByte(parent);

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;

  // **** End DcmReaderInterface ****

/*
  RootDataset readFMI({bool checkPreamble = false, bool allowMissingPrefix = false}) {
	  final bool hadFmi =
        dcmReadFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
    rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? rootDS : null;
  }
*/

  /// Reads a [RootDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootDataset readRootDataset(
      {bool allowMissingFMI = false,
      bool checkPreamble = true,
      bool allowMissingPrefix = false}) {
    try {
      final rds = readRoot(
          allowMissingFMI: allowMissingFMI,
          checkPreamble: checkPreamble,
          allowMissingPrefix: allowMissingPrefix);
      if (rds == null) return null;
      rootDS.parseInfo = getParseInfo();
      //  log.debug('rootDS: $rootDS');
      //  log.debug('RootDS.TS: ${rootDS.transferSyntax}');
      //  log.debug('elementList(${elementList.length})');
    } on ShortFileError catch (e) {
      log.error(e);
      return null;
    } on EndOfDataError catch (e) {
      log.error(e);
    } on InvalidTransferSyntaxError catch (e) {
      log.error(e);
    }
    rootDS.dsBytes = new RDSBytes(rootBD);
    return rootDS;
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

  // **** DcmReaderInterface ****

  //Urgent: flush or fix
  static Element makeTagElement<V>(EBytes eb, int vrIndex, VFFragments fragments) =>
      makeTagElementFromEBytes<V>(eb, vrIndex, fragments);

  /// Reads the [RootDataset] from a [Uint8List].
  static RootDataset readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    RootDataset rds;
    try {
      final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
      final reader = new ByteReader(bd,
          path: path, async: async, fast: fast, fmiOnly: fmiOnly, reUseBD: reUseBD);
      rds = reader.readRoot();
    } on ShortFileError catch (e) {
      log.warn('Short File: $e');
    }
    return rds;
  }

  /// Reads the [RootDataset] from a [File].
  static RootDataset readFile(File file,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool throwOnError = true,
          bool allowMissingFMI: false,
          TransferSyntax targetTS,
          bool reUseBD: true}) =>
// Fix   checkFile(file);
      readBytes(file.readAsBytesSync(),
          path: file.path,
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          throwOnError: throwOnError,
          allowMissingFMI: allowMissingFMI,
          targetTS: targetTS,
          reUseBD: reUseBD);

  /// Reads the [RootDataset] from a [path] ([File] or URL).
  static RootDataset readPath(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool throwOnError = true,
          bool allowMissingFMI = false,
          TransferSyntax targetTS,
          bool reUseBD = true}) =>
//Fix    checkPath(path);
      readFile(new File(path),
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          throwOnError: throwOnError,
          allowMissingFMI: allowMissingFMI,
          targetTS: targetTS);

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readFileFmiOnly(File file,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool throwOnError = true,
          TransferSyntax targetTS,
          bool reUseBD = true}) =>
      readFile(file,
          async: async,
          fast: fast,
          fmiOnly: true,
          throwOnError: true,
          allowMissingFMI: false,
          targetTS: targetTS,
          reUseBD: reUseBD);

  /// Reads only the File Meta Information (FMI), if present.
  static RootDataset readPathFmiOnly(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          bool throwOnError = true,
          TransferSyntax targetTS,
          bool reUseBD = true}) =>
      readPath(path,
          async: async,
          fast: fast,
          fmiOnly: true,
          throwOnError: true,
          allowMissingFMI: false,
          targetTS: targetTS,
          reUseBD: reUseBD);
}
