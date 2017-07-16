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
/// The resulting [Dataset] is a [RootTagDataset].
class TagReader extends DcmReader {
  final RootTagDataset _rootDS;
  TagDataset _currentDS;

  /// Creates a new [TagReader].
  TagReader(ByteData bd,
      {String path = "",
      bool async: true,
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : _rootDS =
            new RootTagDataset(bd: bd, path: path, vfLength: bd.lengthInBytes),
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
  factory TagReader.fromList(List<int> list, RootTagDataset rootDS,
      {String path = "",
      async: true,
      fast: true,
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new TagReader(bd,
        path: path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: true);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].
  RootTagDataset get rootDS => _rootDS;
  TagDataset get currentDS => _currentDS;
  void set currentDS(TagDataset ds) => _currentDS = ds;

  bool readFMI([bool checkPreamble = false]) {
    var hadFmi = dcmReadFMI(checkPreamble);
    rootDS.parseInfo = parseInfo;
    return hadFmi;
  }

  /// Reads a [RootTagDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootTagDataset readRootDataset({bool allowMissingFMI = false}) {
    dcmReadRootDataset(allowMissingFMI: allowMissingFMI);
    rootDS.parseInfo = parseInfo;
    print('parseInfo: $parseInfo');
    return rootDS;
  }

  /// Returns a new [ByteElement].
  //  Called from [DcmReader].
  TagElement makeElementFromBytes(int code, int vrCode, int vfOffset,
          Uint8List vfBytes, int vfLength, bool isEVR,
          [VFFragments fragments]) =>
      TagElement.makeElementFromBytes(
          code, vrCode, vfBytes, vfLength, fragments);

  ///
  TagElement makeElementFromByteData(ByteData bd, bool isEVR) {
    ByteElement be = ByteElement.makeElementFromByteData(bd, isEVR);
    return makeTagElement(be);
  }

  //TODO: decide where to parse Fragments.
  /// Returns a new [ByteElement].
  //  Called from [DcmReader].
  TagElement makeTagElement(ByteElement e, [VFFragments fragments]) =>
      TagElement.makeElementFromByteElement(e);

  /// Returns a new TagSequence.
  /// [vf] is [ByteData] for the complete Value Field of the Sequence.
  SQ makeSequence(int code, List<TagItem> items, ByteData vf,
      [bool hadULength = false, bool isEVR]) {
    Tag tag = Tag.lookup(code);
    SQ sq = new SQ(tag, items, vf.lengthInBytes, hadULength);
    for (TagItem item in items) item.addSQ(sq);
    return sq;
  }

  /// Returns a new [TagItem].
  TagItem makeItem(ByteData bd, TagDataset parent,
          Map<int, Element> elements, int vfLength,
          [bool hadULength = false, TagElement sq]) =>
      new TagItem.fromMap(parent, elements, vfLength, hadULength, sq);

  TagElement makePixelData(int code, int vrCode, int vfOffset,
      Uint8List vfBytes, int vfLength, bool isEVR,
      [VFFragments fragments]) {
    assert(code == kPixelData);
    if (vrCode == VR.kOB.code) {
      if (vfLength == kUndefinedLength) {
        VFFragments fragments = readFragments();
        return new OBPixelData(PTag.kPixelData, vfBytes, vfLength, fragments);
      } else {
        return new OBPixelData(PTag.kPixelData, vfBytes, vfLength);
      }
    } else if (vrCode == VR.kOW.code) {
      assert(vfLength != kUndefinedLength);
      return new OW.fromBytes(PTag.kPixelData, vfBytes, vfLength);
    } else {
      throw 'Invalid VR($vrCode) for Pixel Data';
    }
  }

  // TODO: add Async argument and make it the default
  /// Reads only the File Meta Information ([FMI], if present.
  static RootTagDataset readBytes(Uint8List bytes,
      {String path = "",
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    TagReader reader = new TagReader(bd,
        path: path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        targetTS: targetTS);
    var root = reader.dcmReadRootDataset();
    print(root);
    return root;
  }

  static RootTagDataset readFile(File file,
      {async: true,
      fast = true,
      bool fmiOnly = false,
      TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        targetTS: targetTS);
  }

  static TagDataset readPath(String path,
          {bool async: true,
          bool fast = true,
          bool fmiOnly = false,
          TransferSyntax targetTS}) =>
      readFile(new File(path),
          async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);

  /// Reads only the File Meta Information ([FMI], if present.
  static Dataset readFmiOnly(dynamic pathOrFile,
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
