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
/// The resulting [Dataset] is a [RootTagDataset].
class TagReader extends DcmReader {
  final RootTagDataset _rootDS;
  TagDataset _currentDS;

  /// Creates a new [TagReader].
  TagReader(ByteData bd,
      {String path = "",
        int vfLength,
      bool async: true,
      //TODO: make async work and be the default
      bool fast: true,
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : _rootDS =
            new RootTagDataset.fromByteData(bd, vfLength: vfLength),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

/*  Flush at V0.9.0 if not used.
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
*/

  /// Creates a [ByteReader] from the contents of the [file].
  factory TagReader.fromFile(File file,
      {bool async: false,
        bool fast: true,
        bool fmiOnly = false,
        bool throwOnError = false,
        bool allowMissingFMI = false,
        TransferSyntax targetTS,
        bool reUseBD = true}) {
    Uint8List bytes = file.readAsBytesSync();
    ByteData bd = bytes.buffer.asByteData();
    return new TagReader(bd,
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        targetTS: targetTS);
  }

  /// Creates a [ByteReader] from the contents of the [File] at [path].
  factory TagReader.fromPath(String path,
      {bool async: true,
        bool fast: true,
        bool fmiOnly = false,
        bool throwOnError = false,
        bool allowMissingFMI = false,
        TransferSyntax targetTS,
        bool reUseBD = true}) {
    return new TagReader.fromFile(new File(path),
        async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].
  RootTagDataset get rootDS => _rootDS;
  TagDataset get currentDS => _currentDS;
  void set currentDS(TagDataset ds) => _currentDS = ds;

  RootTagDataset readFMI([bool checkPreamble = false]) {
    var hadFmi = dcmReadFMI(checkPreamble);
    rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? _rootDS : null;
  }

  /// Reads a [RootTagDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootTagDataset readRootDataset({bool allowMissingFMI = false}) {
    dcmReadRootDataset(allowMissingFMI: allowMissingFMI);
    var parseInfo = getParseInfo();
    rootDS.parseInfo = parseInfo;
    return (parseInfo.hadFmi) ? _rootDS : null;
  }

  /// Returns a new [ByteElement].
  //  Called from [DcmReader].
  TagElement makeElementFromBytes(
          int code, int vrCode, int vfOffset, Uint8List vfBytes, int vfLength,
          [VFFragments fragments]) =>
      TagElement.makeElementFromBytes(
          code, vrCode,  vfLength, vfBytes, fragments);

/* Flush if not used
  ///
  TagElement makeElementFromByteData(ByteData bd, [VFFragments fragments]) {
    ByteElement be = ByteElement.makeElementFromByteData(bd, isEVR);
    return makeTagElement(be);
  }
*/

  //TODO: decide where to parse Fragments.
  /// Returns a new [ByteElement].
  //  Called from [DcmReader].
  TagElement makeTagElement(ByteElement e, [VFFragments fragments]) =>
      TagElement.makeElementFromByteElement(e);

  /// Returns a new TagSequence.
  /// [vf] is [ByteData] for the complete Value Field of the Sequence.
  SQ makeSequence(ByteData bd, List<TagItem> items, int vfLength, bool isEVR) {
    int group = bd.getUint16(0);
    int elt = bd.getUint16(2);
    int code = (group << 16) & elt;
    Tag tag = Tag.lookup(code);
//    int vfOffset = (isEVR) ? 12 : 8;
    SQ sq = new SQ(tag, items, vfLength);
    for (TagItem item in items) item.addSQ(sq);
    return sq;
  }

  /// Returns a new [TagItem].
  TagItem makeItem(ByteData bd, TagDataset parent, int vfLength,
      Map<int, Element> map, [Map<int,
      Element> dupMap]) =>
      new TagItem.fromDecoder(bd, parent,  vfLength, map, dupMap);

  TagElement makePixelData(
      int code, int vrCode, int vfOffset, Uint8List vfBytes, int vfLength,
      [VFFragments fragments]) {
    assert(code == kPixelData);
    if (vrCode == VR.kOB.code) {
        return new OBPixelData(PTag.kPixelData, vfBytes, vfLength, fragments);
      } else if (vrCode == VR.kOW.code) {
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
    var root = reader.readRootDataset();
    log.debug(root);
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
