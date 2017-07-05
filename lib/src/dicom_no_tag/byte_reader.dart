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

class ByteReader extends DcmReader {
  final RootByteDataset rootDS;
  ByteDataset _currentDS;

  /// Creates a new [ByteReader].
  ByteReader(ByteData bd,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : rootDS = new RootByteDataset(bd, path: path, vfLength: bd.lengthInBytes),
        super(bd,
            path: path,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory ByteReader.fromList(List<int> list, RootDataset rootDS,
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

  ByteDataset get currentDS => _currentDS;
  void set currentDS(ByteDataset ds) => _currentDS = ds;

  ByteElement makeElement(bool isEVR, int code, int vrCode, Uint8List vfBytes, [List values]) =>
      throw new UnimplementedError();

  ByteElement makeElementFromBytes(bool isEVR, int code, int vrCode, Uint8List vfBytes) =>
      throw new UnimplementedError();

  ByteElement makeElementFromByteData(bool isEVR, int code, int vrCode, ByteData e) =>
      (isEVR) ? new EVRElement(bd) : new IVRElement(e);

  void add(ByteElement e) => currentDS.add(e);

  ByteItem makeItem(ByteData bd, ByteDataset parent, Map<int, Element> elements, int vfLength,
          bool hadULength,
          [ByteElement sq]) =>
      new ByteItem.fromMap(bd, parent, elements, vfLength, hadULength, sq);

  ByteSQ makeSequence(
          bool isEVR, ByteData bd, ByteDataset ds, List<ByteItem> items, bool hadULength) {
 //   List<ByteItem> bItems = items as List<ByteItem>;
    ByteSQ sq = (isEVR)
        ? new EVRSequence(bd, currentDS, items, hadULength)
        : new IVRSequence(bd, currentDS, items, hadULength);
    for (ByteItem item in items) item.addSQ(sq);
   // addSequence(items, sq);
    return sq;
    }

  List<Dataset> addSequence(List<Dataset> items, Element sq) {
    for (ByteItem item in items) item.addSQ(sq);
    return items;
  }

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
  static Dataset readBytes(Uint8List bytes,
      {String path = "", bool fmiOnly = false, fast = true, TransferSyntax targetTS}) {
    ByteData bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    ByteReader reader = new ByteReader(bd, path: path, fmiOnly: fmiOnly, targetTS: targetTS);
    return reader.readRootByteDataset();
  }

  static Dataset readFile(File file,
          {bool fmiOnly = false, fast = true, TransferSyntax targetTS}) =>
      readBytes(file.readAsBytesSync(), path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);

  static Dataset readPath(String path,
          {bool fmiOnly = false, fast = true, TransferSyntax targetTS}) =>
      readFile(new File(path), fmiOnly: fmiOnly, targetTS: targetTS);

  /// Reads only the File Meta Information ([FMI], if present.
  static Dataset readFmiOnly(dynamic pathOrFile, {fast = true, TransferSyntax targetTS}) {
    if (pathOrFile is String) readPath(pathOrFile, fmiOnly: true, fast: fast, targetTS: targetTS);
    if (pathOrFile is File) readFile(pathOrFile, fmiOnly: true, fast: fast, targetTS: targetTS);
    throw 'Invalid path or file: $pathOrFile';
  }
}
