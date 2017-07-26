// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/dcm.dart';
import 'dcm_reader.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootByteDataset].
class ByteReader extends DcmReader {
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
      TransferSyntax targetTS,
      bool reUseBD = true})
      : _rootDS = new RootByteDataset.fromByteData(bd,
            path: path, vfLength: bd.lengthInBytes),
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
      TransferSyntax targetTS,
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
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    Uint8List bytes = file.readAsBytesSync();
    ByteData bd = bytes.buffer.asByteData();
    return new ByteReader(bd,
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        targetTS: targetTS);
  }

  /// Creates a [ByteReader] from the contents of the [File] at [path].
  factory ByteReader.fromPath(String path,
      {bool async: true,
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    return new ByteReader.fromFile(new File(path),
        async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].
  RootByteDataset get rootDS => _rootDS;
  ByteDataset get currentDS => _currentDS;
  void set currentDS(ByteDataset ds) => _currentDS = ds;

  RootByteDataset readFMI([bool checkPreamble = false]) {
    bool hadFmi = dcmReadFMI(checkPreamble);
    rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? _rootDS : null;
  }

  /// Reads a [RootByteDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootByteDataset readRootDataset({bool allowMissingFMI = false}) {
    try {
      dcmReadRootDataset(allowMissingFMI: allowMissingFMI);
      var parseInfo = getParseInfo();
      rootDS.parseInfo = parseInfo;
      log.debug('elementList(${elementList.length})');
      //    log.debug2('Elements: $elementList');
    } on ShortFileError catch (e) {
      log.error(e);
      return null;
    }
    return _rootDS;
  }

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
  TagElement makeTagElement(ByteElement e) =>
      TagElement.makeElementFromBytes(e.code, e.vrCode, e.vfBytes, e.vfLength);

/*
  //Urgent: flush or fix
  TagElement makeElementFromBytePixelData(Element e, bool isEVR) =>
      TagElement.makeElementFromBytes(
          e.code, e.vrCode, e.vfBytes, e.vfLength, e.fragments);
*/

  /// Returns a new ByteSequence.
  /// [bd] is the complete [ByteElement] for the Sequence.
  ByteElement makeSequence(
      ByteData bd, List<ByteItem> items, int vfLength, bool isEVR) {
    //TODO: figure out how to create a ByteSequence with one call.
    ByteElement sq = (isEVR)
        ? new EVRByteSQ(bd, currentDS, items)
        : new IVRByteSQ(bd, currentDS, items);
    for (ByteItem item in items) item.addSQ(sq);
    return sq;
  }

  /// Returns a new [ByteItem].
  ByteItem makeItem(ByteData bd, ByteDataset parent, int vfLength,
          Map<int, Element> map, [Map<int, Element> dupMap]) =>
      new ByteItem.fromDecoder(bd, parent, vfLength, map, dupMap);

  /// Reads only the File Meta Information ([FMI], if present.
  static RootByteDataset readBytes(Uint8List bytes,
      {String path = "",
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      TransferSyntax targetTS}) {
    RootByteDataset rds;
    try {
      ByteData bd =
          bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
      ByteReader reader = new ByteReader(bd,
          path: path,
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          targetTS: targetTS);
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
          TransferSyntax targetTS}) =>
      readBytes(file.readAsBytesSync(),
          path: file.path,
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          targetTS: targetTS);

  static ByteDataset readPath(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          TransferSyntax targetTS}) =>
      readFile(new File(path),
          async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);

  /// Reads only the File Meta Information ([FMI], if present.
  static ByteDataset readFmiOnly(dynamic pathOrFile,
      {async = true, fast = true, TransferSyntax targetTS}) {
    var func;
    if (pathOrFile is String) {
      func = readPath;
    } else if (pathOrFile is File) {
      func = readFile;
    } else {
      throw 'Invalid path or file: $pathOrFile';
    }
    return func(pathOrFile,
        async: async, fmiOnly: true, fast: fast, targetTS: targetTS);
  }
}
