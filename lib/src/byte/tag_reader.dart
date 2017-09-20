// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/dcm.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

import 'dcm_reader.dart';

/// Creates a new [TagReader], which is decoder for Binary DICOM
/// (application/dicom).
class TagReader extends DcmReader {
	@override
  final RootTagDataset rootDS;
  TagDataset _currentDS;
  Map<int, TagElement> _currentMap;
	Map<int, TagElement> _currentDupMap;

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
      : rootDS = new RootTagDataset.fromByteData(bd, vfLength: vfLength),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

  /// Creates a [TagReader] from the contents of the [file].
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
        path: file.path, async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  /// Creates a [TagReader] from the contents of the [File] at [path].
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

	// **** DcmReaderInterface ****

	@override
  TagDataset get currentDS => _currentDS;

  @override
  set currentDS(Dataset ds) => _currentDS = ds;

	/// The current [TagElement] [Map].
	@override
	Map<int, TagElement> get currentMap => _currentMap;
	@override
	set currentMap(Map<int, Element> map) => _currentMap = map;

	/// The current duplicate [TagElement] [Map].
	@override
	Map<int, TagElement> get currentDupMap => _currentDupMap;
	@override
	set currentDupMap(Map<int, Element> map) => _currentDupMap = map;

	/// Returns an empty [Map<int, TagElement].
	@override
	Map<int, TagElement> makeEmptyMap() => <int, TagElement>{};

  @override
  TagElement makeElement(int vrIndex, Tag tag, ByteData bd,
          [int vfLength, Uint8List vfBytes]) =>
      TagElement.makeElementFromBytes(tag, vfBytes, vfLength, tag.vrIndex);

	@override
	String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

	@override
  TagElement makePixelData(
    _vrIndex,
    ByteData bd, [
    VFFragments fragments,
    Tag tag,
    int vfLength,
    ByteData vfBytes,
  ]) =>
      throw new UnimplementedError();


/*  /// Returns a new [TagElement].
  //  Called from [DcmReader].
  TagElement makeElementFromBytes(
          int code, int vrCode, int vfOffset, Uint8List vfBytes, int vfLength,
          [VFFragments fragments]) =>
      TagElement.makeElementFromBytes(
          code, vrCode, vfLength, vfBytes, fragments);

  //TODO: decide where to parse Fragments.
  /// Returns a new [TagElement].
  //  Called from [DcmReader].
  TagElement makeTagElement(TagElement e, [VFFragments fragments]) =>
      TagElement.makeElementFromTagElement(e);
*/

  /// Returns a new TagSequence.
  @override
  SQ makeSQ(ByteData bd, Dataset parent, List items, int vfLength, bool isEVR) {
    int group = bd.getUint16(0);
    int elt = bd.getUint16(2);
    int code = (group << 16) & elt;
    Tag tag = Tag.lookupByCode(code);
//    int vfOffset = (isEVR) ? 12 : 8;
    SQ sq = new SQ(tag, parent, items, vfLength);
    for (TagItem item in items) item.addSQ(sq);
    return sq;
  }

	/// Returns a new [TagItem].
	@override
	TagItem makeItem(ByteData bd, Dataset parent, int vfLength, Map<int, Element> map,
	                 [Map<int, Element> dupMap]) =>
			new TagItem.fromDecoder(bd, parent, vfLength, map, dupMap);

	@override
	String itemInfo(ByteItem item) => (item == null) ? 'Item item = null' : item.info;

	/* Flush if not needed
  TagElement makePixelData(int vrIndex, TagElement e, VFFragments fragments) {
    assert(e.code == kPixelData);
    Tag tag = PTag.kPixelData;
    VR vr = VR.vrList[vrIndex];
    if (vr == VR.kOB)
      return new OBPixelData(tag, e.vfBytes, e.vfLength, fragments);
    if (vr == VR.kOW)
      return new OWPixelData.fromBytes(tag, e.vfBytes, e.vfLength, fragments);
    if (vr == VR.kUN)
      return new UNPixelData.fromBytes(tag, vfBytes, vfLength, fragments);
    return invalidVRError(VR.lookup(vrCode), 'TagReader.makePixelData');
  }
*/


	// **** End DcmReaderInterface ****

	RootTagDataset readFMI({bool checkPreamble = false}) {
		var hadFmi = dcmReadFMI(checkPreamble: checkPreamble);
		rootDS.parseInfo = getParseInfo();
		return (hadFmi) ? rootDS : null;
	}

	/// Reads a [RootTagDataset] from [this], stores it in [rootDS],
	/// and returns it.
	RootTagDataset readRootDataset({bool allowMissingFMI = false}) {
		dcmReadRootDataset(allowMissingFMI: allowMissingFMI);
		var parseInfo = getParseInfo();
		rootDS.parseInfo = parseInfo;
		return (parseInfo.hadFmi) ? rootDS : null;
	}

	// TODO: add Async argument and make it the default
  /// Reads only the File Meta Information ([FMI], if present.
  static RootTagDataset readBytes(Uint8List bytes,
      {String path = "",
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      TransferSyntax targetTS}) {
    ByteData bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    TagReader reader = new TagReader(bd,
        path: path, async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);
    var root = reader.readRootDataset();
    log.debug(root);
    return root;
  }

  static RootTagDataset readFile(File file,
      {async: true, fast = true, bool fmiOnly = false, TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, async: async, fast: fast, fmiOnly: fmiOnly, targetTS: targetTS);
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
    return func(pathOrFile, async: async, fmiOnly: true, fast: fast, targetTS: targetTS);
  }
}
