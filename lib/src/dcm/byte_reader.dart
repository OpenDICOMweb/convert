// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/byte_dataset.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/dcm.dart';
import 'dcm_reader.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootByteDataset].
class ByteReader extends DcmReader {
  static final Logger log = new Logger('DcmReader.ByteReader');
  final RootByteDataset _rootDS;
  ByteDataset _currentDS;

  /// Creates a new [ByteReader].
  ByteReader(ByteData bd,
      {String path = "",
      //TODO: make async work and be the default
      bool async = false,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntaxUid targetTS,
      bool reUseBD = true})
      : _rootDS =
            new RootByteDataset.fromByteData(bd, vfLength: bd.lengthInBytes),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

/* Flush at V0.9.0 if not used.
   /// Creates a [Uint8List] with the same length as [list<int>];
  /// and copies the values to the [Uint8List].  Values are truncated
  /// to fit in the [Uint8List] as they are copied.
  factory ByteReader.fromList(List<int> list,
      {String path = "",
      bool async: true,
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntaxUid targetTS,
      bool reUseBD = true}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new ByteReader(bd,
        path: path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: true);
  }
*/

  /// Creates a [ByteReader] from the contents of the [file].
  factory ByteReader.fromFile(File file,
      {bool async: false,
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntaxUid targetTS,
      bool reUseBD = true}) {
    Uint8List bytes = file.readAsBytesSync();
    ByteData bd = bytes.buffer.asByteData();
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
      TransferSyntaxUid targetTS,
      bool reUseBD = true}) {
    return new ByteReader.fromFile(new File(path),
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: reUseBD);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].
  RootByteDataset get rootDS => _rootDS;
  ByteDataset get currentDS => _currentDS;
  void set currentDS(ByteDataset ds) => _currentDS = ds;

  RootByteDataset readFMI([bool checkPreamble = false]) {
    bool hadFmi = dcmReadFMI(checkPreamble);
    _rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? _rootDS : null;
  }

  /// Reads a [RootByteDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootByteDataset readRootDataset({bool allowMissingFMI = false}) {
    try {
      dcmReadRootDataset(allowMissingFMI: allowMissingFMI);
      _rootDS.parseInfo = getParseInfo();
      log.debug('rootDS: $rootDS');
      log.debug('RootDS.TS: ${rootDS.transferSyntax}');
      log.debug('elementList(${elementList.length})');
    } on ShortFileError catch (e) {
      log.error(e);
      return null;
    } on EndOfDataError catch (e) {
      log.error(e);
    } on InvalidTransferSyntaxError catch (e) {
      log.error(e);
    }
    _rootDS.bd = bdRead;
    return _rootDS;
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

  // Interface
  String show(ByteElement e) => (e == null) ? 'Element e = null' : e.info;

  String showItem(ByteItem item) =>
      (item == null) ? 'Item item = null' : item.info;
/*
  /// Returns a new [ByteElement].
  // Called from [DcmReader].
  ByteElement makeElementFromBytes(
          int code, int vrCode, int vfOffset, Uint8List vfBytes, int vfLength,
          [VFFragments fragments]) =>
      (isEVR)
          ? new EVRElement.fromBytes(code, vrCode, vfOffset, vfBytes)
          : new IVRElement.fromBytes(code, vrCode, vfOffset, vfBytes);
*/

/*  /// Returns a new [ByteElement].
  //  Called from [DcmReader].
  ByteElement makeElementFromByteData(ByteData bd, [VFFragments fragments]) =>
      (isEVR)
          ? new EVRElement.fromByteData(bd)
          : new IVRElement.fromByteData(bd);*/
/*
  //Urgent: flush or fix
  /// Makes a PixelData [Element] from [ByteData]
  /// Note: ByteReader doesn't handel fragments.
  ByteElement makePixelData(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      makeElementFromBytes(
          code, vrCode, vfOffset, vfBytes, vfLength, fragments);
*/

  //Urgent: flush or fix
  ByteElement makeElement(int vrIndex, ByteData bd) =>
      (isEVR) ? EVR.makeElement(vrIndex, bd) : IVR.makeElement(vrIndex, bd);

  ByteElement makePixelData(int vrIndex, ByteData bd,
          [VFFragments fragments]) =>
      (isEVR)
          ? EVR.makePixelData(vrIndex, bd, fragments)
          : IVR.makePixelData(vrIndex, bd, fragments);

  /// Returns a new ByteSequence.
  /// [bd] is the complete [ByteElement] for the Sequence.
  ByteElement makeSQ(ByteData bd, ByteDataset parent, List<ByteItem> items,
      int vfLength, bool isEVR) {
    //TODO: figure out how to create a ByteSequence with one call.
    ByteElement sq = (isEVR)
        ? EVR.makeSQ(bd, currentDS, items)
        : IVR.makeSQ(bd, currentDS, items);
    for (ByteItem item in items) item.addSQ(sq);
    return sq;
  }

  /// Returns a new [ByteItem].
  ByteItem makeItem(
          ByteData bd, ByteDataset parent, int vfLength, Map<int, Element> map,
          [Map<int, Element> dupMap]) =>
      new ByteItem.fromDecoder(bd, parent, vfLength, map, dupMap);

  //Urgent: flush or fix
  static TagElement makeTagElement(ByteElement e) =>
      TagElement.makeElementFromBytes(
          e.code, e.vrCode, e.vfLength, e.vfBytes, e.fragments);

  static TagElement makeTagPixelData(ByteElement e) {
    assert(e.code == kPixelData);
    if (e is OBPixelData)
      return new OBPixelData.fromBytes(
          e.tag, e.vfBytes, e.vfLength, e.fragments);
    if (e is OW)
      return new OBPixelData.fromBytes(
          e.tag, e.vfBytes, e.vfLength, e.fragments);
    if (e is UN == VR.kUN.code)
      return new UNPixelData.fromBytes(
          e.tag, e.vfBytes, e.vfLength, e.fragments);
    return invalidVRError(e.vr, 'TagReader.makePixelData');
  }

  /// Reads only the File Meta Information ([FMI], if present.
  static RootByteDataset readBytes(Uint8List bytes,
      {String path = "",
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      allowMissingFMI = false,
      TransferSyntaxUid targetTS,
      bool reUseBD = true}) {
    RootByteDataset rds;
    try {
      ByteData bd =
          bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
      ByteReader reader = new ByteReader(bd,
          path: path,
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          throwOnError: throwOnError,
          allowMissingFMI: allowMissingFMI,
          targetTS: targetTS,
          reUseBD: reUseBD);
      rds = reader.readRootDataset();
    } on ShortFileError catch (e) {
      log.warn('Short File: $e');
    }
    return rds;
  }

  static RootByteDataset readFile(File file,
      {bool async: true,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI: false,
      TransferSyntaxUid targetTS,
      bool reUseBD: true}) {
// Fix   checkFile(file);
    return readBytes(file.readAsBytesSync(),
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: reUseBD);
  }

  static ByteDataset readPath(String path,
      {bool async: true,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      allowMissingFMI = false,
      TransferSyntaxUid targetTS,
      bool reUseBD = true}) {
//Fix    checkPath(path);
    return readFile(new File(path),
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS);
  }

  /// Reads only the File Meta Information ([FMI], if present.
  static ByteDataset readFmiOnly(dynamic pathOrFile,
      {bool async: true,
      bool fast = true,
      bool fmiOnly = false,
      bool throwOnError = true,
      TransferSyntaxUid targetTS,
      bool reUseBD = true}) {
    var func;
    if (pathOrFile is String) {
      func = readPath;
    } else if (pathOrFile is File) {
      func = readFile;
    } else {
      throw 'Invalid path or file: $pathOrFile';
    }
    return func(pathOrFile,
        async: async,
        fast: fast,
        fmiOnly: true,
        throwOnError: true,
        allowMissingFMI: false,
        targetTS: targetTS,
        reUseBD: reUseBD);
  }
}
