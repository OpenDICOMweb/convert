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
/// is a [RootTagDataset].
class TagReader extends DcmReader {
  final RootTagDataset _rootDS;
  TagDataset _currentDS;

  /// Creates a new [TagReader].
  TagReader(ByteData bd,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : _rootDS =
            new RootTagDataset(bd: bd, path: path, vfLength: bd.lengthInBytes),
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
  factory TagReader.fromList(List<int> list, RootTagDataset rootDS,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new TagReader(bd,
        path: path,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: true);
  }

  RootTagDataset get rootDS => _rootDS;
  TagDataset get currentDS => _currentDS;
  void set currentDS(TagDataset ds) => _currentDS = ds;

  //Flush if not needed
  TagElement makeElement(int code, int vrCode,
          [List values, bool isEVR = true]) =>
      TagElement.makeElement(code, vrCode, values, isEVR);

  TagElement makeElementFromBytes(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      TagElement.makeElementFromBytes(
          code, vrCode, vfBytes, vfLength, fragments);

  // Flush if not needed
  TagElement makeElementFromByteData(ByteData e, bool isEVR) =>
      throw new UnimplementedError();

  void add(TagElement e) => currentDS.add(e);

  TagItem makeItem(ByteData bd, TagDataset parent,
          Map<int, TagElement> elements, int vfLength, bool hadULength,
          [TagElement sq]) =>
      new TagItem.fromMap(bd, parent, elements, vfLength, hadULength, sq);

  SQ makeSequence(int code, List<TagItem> items, ByteData vfBD, bool hadULength,
      [bool isEVR]) {
    //   List<ByteItem> bItems = items as List<ByteItem>;
    Tag tag = Tag.lookup(code);
    SQ sq = new SQ(tag, items, vfBD.lengthInBytes, hadULength);

    for (TagItem item in items) item.addSQ(sq);
    // addSequence(items, sq);
    return sq;
  }

/* Flush when fully debugged
  List<Dataset> addSequence(List<Dataset> items, Element sq) {
    for (TagItem item in items) item.addSQ(sq);
    return items;
  }*/

  /// Reads only the File Meta Information ([FMI], if present.
  static Dataset readBytes(Uint8List bytes, Dataset rootDS,
      {String path = "", bool fmiOnly = false, TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    TagReader reader =
        new TagReader(bd, path: path, fmiOnly: fmiOnly, targetTS: targetTS);
    return reader.readRootDataset();
  }

  static RootDataset readFile(File file, RootDataset rootDS,
      {bool fmiOnly = false, TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes, rootDS,
        path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  /// Reads only the File Meta Information ([FMI], if present.
  static RootDataset readFileFmiOnly(File file, RootDataset rootDS,
          {String path = "", TransferSyntax targetTS}) =>
      readFile(file, rootDS, fmiOnly: true, targetTS: targetTS);
}
