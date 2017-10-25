// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/byte/dcm_reader.dart';
import 'package:dcm_convert/src/byte/dcm_reader_interface.dart';
import 'package:dcm_convert/src/errors.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootByteDataset].
class ByteReader extends DcmReader implements DcmReaderInterface {
  @override
  final RootByteDataset rootDS;
  Dataset _currentDS;
  ElementList _elements;

  /// Creates a new [ByteReader], which is decoder for Binary DICOM
  /// (application/dicom).
  ByteReader(ByteData bd,
      {String path = '',
      //TODO: make async work and be the default
      bool async = false,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : rootDS = new RootByteDataset(bd, vfLength: bd.lengthInBytes),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

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
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: reUseBD);
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
  @override
  set currentDS(Dataset ds) => _currentDS = ds;

  /// The current [Element] [Map].
  @override
  List<Element> get currentElements => _elements;
  @override
  set currentElements(List<Element> eList) => _elements = eList;

  /// The current duplicate [List<Element>].
  @override
  List<Element> get duplicates => currentDS.elements.duplicates;

  /// Returns an empty [Map<int, Element].
  @override
  Map<int, Element> makeEmptyMap() => <int, Element>{};

  //Urgent: flush or fix
  @override
  Element makeElement(int index, List<V> values, ByteData bd,
      [int vfLengthField, Uint8List vfBytes]) {
    int tag = Tag.lookupByCode(index);
    return (isEVR)
        ? EVR.makeElement(index, tag, bytes)
        : IVR.makeElement(index, tag, bytes);
  }

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  Element makePixelData(
    int vrIndex,
    ByteData bytes, [
    VFFragments fragments,
    Tag tag,
    int vfLengthField,
    ByteData vfBytes,
  ]) =>
      (isEVR)
          ? EVR.makePixelData(vrIndex, bytes, fragments)
          : IVR.makePixelData(vrIndex, bytes, fragments);

  /// Returns a new ByteSequence.
  @override
  Element makeSQ(Dataset parent, List items, int vfLengthField, ByteData bd, {bool
  isEVR }) {
    //TODO: figure out how to create a ByteSequence with one call.
	  final SQbyte sq =
        (isEVR) ? EVR.makeSQ(bd, currentDS, items) : IVR.makeSQ(bd, currentDS, items);
    for (ByteItem item in items) item.addSQ(sq);
    return sq;
  }

  /// Returns a new [ByteItem].
  @override
  ByteItem makeItem(Dataset parent, ElementList elements, int vfLengthField,
          [ByteData bd]) =>
      new ByteItem.fromList( parent, elements, vfLengthField, bd);

  @override
  String itemInfo(ByteItem item) => (item == null) ? 'Item item = null' : item.info;

  // **** End DcmReaderInterface ****

/*
  RootByteDataset readFMI({bool checkPreamble = false, bool allowMissingPrefix = false}) {
	  final bool hadFmi =
        dcmReadFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
    rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? rootDS : null;
  }
*/

  /// Reads a [RootByteDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootByteDataset readRootDataset(
      {bool allowMissingFMI = false,
      bool checkPreamble = true,
      bool allowMissingPrefix = false}) {
    try {
      final RootByteDataset rds = dcmReadRootDataset(
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
    rootDS.bd = rootBD;
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
  static Element makeTagElement(Element be) => be.tagElementFromBytes;

  //Urgent: flush or fix
  static Uint8Base makeTagPixelData(Element e) {
    assert(e.code == kPixelData);
    print('makePixelData: ${e.info}');
    if (e.vr == VR.kOB)
      return new OBtagPixelData.fromBytes(e.tag, e.vfBytes, e.vfLengthField,
		                                          rootDS.transferSyntax, e.fragments);
    if (e.vr == VR.kOW)
      return new OWtagPixelData.fromBytes(e.tag, e.vfBytes, e.vfLengthField, e.fragments);
    if (e.vr == VR.kOB)
      return new UNtagPixelData.fromBytes(e.tag, e.vfBytes, e.vfLengthField, e.fragments);
    print('makePixelData: ${e.info}');
    return invalidVRError(e.vr, 'TagReader.makePixelData');
  }

  /// Reads the [RootByteDataset] from a [Uint8List].
  static RootByteDataset readBytes(Uint8List bytes,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    RootByteDataset rds;
    try {
      final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
      final reader = new ByteReader(bd,
          path: path,
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          throwOnError: throwOnError,
          allowMissingFMI: allowMissingFMI,
          targetTS: targetTS,
          reUseBD: reUseBD);
      rds = reader.dcmReadRootDataset();
    } on ShortFileError catch (e) {
      log.warn('Short File: $e');
    }
    return rds;
  }

  /// Reads the [RootByteDataset] from a [File].
  static RootByteDataset readFile(File file,
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


  /// Reads the [RootByteDataset] from a [path] ([File] or URL).
  static RootByteDataset readPath(String path,
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

  /// Reads only the File Meta Information ([FMI], if present.
  static RootByteDataset readFileFmiOnly(File file,
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

/// Reads only the File Meta Information ([FMI], if present.
static RootByteDataset readPathFmiOnly(String path,
{bool async: true,
bool fast = true,
bool fmiOnly = false,
bool throwOnError = true,
TransferSyntax targetTS,
bool reUseBD = true}) =>

readPath(path, async: async, fast: fast, fmiOnly: true, throwOnError: true,
allowMissingFMI: false, targetTS: targetTS, reUseBD: reUseBD);

}
