// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'dcm_reader.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootByteDataset].
class ByteReader extends DcmReader {
  final RootByteDataset _rootDS;
  ByteDataset _currentDS;

  /// Creates a new [ByteReader].
  ByteReader(ByteData bd,
      {String path = "",
      bool async: true,
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : _rootDS =
            new RootByteDataset(bd, path: path, vfLength: bd.lengthInBytes),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

  /// Creates a [Uint8List] with the same length as [list<int>];
  /// and copies the values to the [Uint8List].  Values are truncated
  /// to fit in the [Uint8List] as they are copied.
  factory ByteReader.fromList(List<int> list, RootByteDataset rootDS,
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

  // The following Getters and Setters provide the correct [Type].
  RootByteDataset get rootDS => _rootDS;
  ByteDataset get currentDS => _currentDS;
  void set currentDS(ByteDataset ds) => _currentDS = ds;

  bool readByteFMI([bool checkPreamble = false]) {
    var hadFmi = dcmReadFMI(checkPreamble);
    rootDS.parseInfo = parseInfo;
    return hadFmi;
  }

  /// Reads a [RootDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  Dataset readRootByteDataset({bool allowMissingFMI = false}) {
    readRootDataset(allowMissingFMI: allowMissingFMI);
    rootDS.parseInfo = parseInfo;
    return rootDS;
  }

  ByteElement makeElementFromBytes(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      (isEVR)
          ? new EVRElement.fromBytes(code, vrCode, vfOffset, vfBytes)
          : new IVRElement.fromBytes(code, vrCode, vfOffset, vfBytes);

  //Urgent: fix
  /// Makes a PixelData [Element] from [ByteData]
  /// Note: ByteReader doesn't handel fragments.
  ByteElement makePixelData(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      makeElementFromBytes(code, vrCode, vfOffset, vfBytes, vfLength, isEVR);

  TagElement makeTagElementFromBytePixelData(BytePixelData e, bool isEVR) =>
      TagElement.makeElementFromBytes(
          e.code, e.vrCode, e.vfBytes, e.vfLength, e.fragments);

  /// Returns a new ByteSequence.
  /// [e] is the complete [ByteData] for the Sequence.
  ByteSQ makeSequence(int code, List<ByteItem> items, ByteData e,
      [bool hadULength = false, bool isEVR = true]) {
    //TODO: figure out how to create a ByteSequence with one call.
    ByteSQ sq = (isEVR)
        ? new EVRSequence.fromByteData(e, currentDS, items, hadULength)
        : new IVRSequence.fromByteData(e, currentDS, items, hadULength);
    for (ByteItem item in items) item.addSQ(sq);
    return sq;
  }

  /// Returns a new [ByteItem].
  ByteItem makeItem(ByteData bd, ByteDataset parent,
          Map<int, ByteElement> elements, int vfLength,
          [bool hadULength = false, ByteElement sq]) =>
      new ByteItem.fromMap(bd, parent, elements, vfLength, hadULength, sq);

  /// Reads only the File Meta Information ([FMI], if present.
  static ByteDataset readBytes(Uint8List bytes,
      {String path = "",
      async = true,
      fast = true,
      bool fmiOnly = false,
      TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    ByteReader reader = new ByteReader(bd,
        path: path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        targetTS: targetTS);
    return reader.readRootByteDataset();
  }

  static ByteDataset readFile(File file,
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
    func(pathOrFile,
        async: async, fmiOnly: true, fast: fast, targetTS: targetTS);
  }
}
