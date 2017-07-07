// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'dcm_reader.dart';

/// A decoder for Binary DICOM (application/dicom).  The resulting [Dataset]
/// is a [RootByteDataset].
class ByteReader extends DcmReader {
  final RootByteDataset _rootDS;
  ByteDataset _currentDS;

  /// Creates a new [ByteReader].
  ByteReader(ByteData bd,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : _rootDS =
            new RootByteDataset(bd, path: path, vfLength: bd.lengthInBytes),
        super(bd,
            path: path,
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
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new ByteReader(bd,
        path: path,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: true);
  }

  RootByteDataset get rootDS => _rootDS;
  ByteDataset get currentDS => _currentDS;
  void set currentDS(ByteDataset ds) => _currentDS = ds;

  //Flush if not needed
  ByteElement makeElement(int code, int vrCode, [List values, bool isEVR]) =>
      throw new UnimplementedError();

  //Flush if not needed
  ByteElement makeElementFromBytes(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      (isEVR)
          ? new EVRElement.fromBytes(code, vrCode, vfOffset, vfBytes)
          : new IVRElement.fromBytes(code, vrCode, vfOffset, vfBytes);

  ByteElement makeElementFromByteData(ByteData e, bool isEVR) =>
      (isEVR) ? new EVRElement.fromByteData(e) : new IVRElement.fromByteData(e);

  //Urgent: fix
  /// Makes a PixelData [Element] from [ByteData]
  /// Note: ByteReader doesn't handel fragments.
  ByteElement makePixelData(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      makeElementFromBytes(code, vrCode, vfOffset, vfBytes, vfLength, isEVR);

  TagElement makeTagElementFromByteElement(ByteElement e, bool isEVR) =>
      TagElement.makeElementFromBytes(e.code, e.vrCode, e.vfBytes, e.vfLength);

  TagElement makeTagElementFromBytePixelData(BytePixelData e, bool isEVR) =>
      TagElement.makeElementFromBytes(
          e.code, e.vrCode, e.vfBytes, e.vfLength, e.fragments);

  ByteItem makeItem(ByteData bd, ByteDataset parent, Map<int, Element> elements,
          int vfLength, bool hadULength,
          [ByteElement sq]) =>
      new ByteItem.fromMap(bd, parent, elements, vfLength, hadULength, sq);

  ByteSQ makeSequence(
      int code, List<ByteItem> items, ByteData e, bool hadULength,
      [bool isEVR = true]) {
    ByteSQ sq = (isEVR)
        ? new EVRSequence.fromByteData(e, currentDS, items, hadULength)
        : new IVRSequence.fromByteData(e, currentDS, items, hadULength);
    for (ByteItem item in items) item.addSQ(sq);
    return sq;
  }

  void add(ByteElement e) => currentDS.add(e);
/*

  List<Dataset> addSequence(List<Dataset> items, Element sq) {
    for (ByteItem item in items) item.addSQ(sq);
    return items;
  }
*/

  bool readFMI([bool checkPreamble = false]) {
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

  /// Reads only the File Meta Information ([FMI], if present.
  static ByteDataset readBytes(Uint8List bytes,
      {String path = "",
      bool fmiOnly = false,
      fast = true,
      TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    ByteReader reader =
        new ByteReader(bd, path: path, fmiOnly: fmiOnly, targetTS: targetTS);
    return reader.readRootByteDataset();
  }

  static Dataset readFile(File file,
          {bool fmiOnly = false, fast = true, TransferSyntax targetTS}) =>
      readBytes(file.readAsBytesSync(),
          path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);

  static Dataset readPath(String path,
          {bool fmiOnly = false, fast = true, TransferSyntax targetTS}) =>
      readFile(new File(path), fmiOnly: fmiOnly, targetTS: targetTS);

  /// Reads only the File Meta Information ([FMI], if present.
  static Dataset readFmiOnly(dynamic pathOrFile,
      {fast = true, TransferSyntax targetTS}) {
    if (pathOrFile is String)
      readPath(pathOrFile, fmiOnly: true, fast: fast, targetTS: targetTS);
    if (pathOrFile is File)
      readFile(pathOrFile, fmiOnly: true, fast: fast, targetTS: targetTS);
    throw 'Invalid path or file: $pathOrFile';
  }
}
