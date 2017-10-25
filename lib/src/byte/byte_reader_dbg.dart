// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/byte_dataset.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

import 'dcm_reader.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootByteDataset].
class ByteReader extends DcmReader {
	@override
	final RootByteDataset rootDS;
  ByteDataset _currentDS;
  Map<int, Element> _currentMap;
  Map<int, Element> _currentDupMap;

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
      : rootDS = new RootByteDataset.fromByteData(bd, dsLength: bd.lengthInBytes),
        super(bd,
            path: path,
            async: async,
            fast: fast,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
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
      TransferSyntax targetTS,
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

  // **** DcmReaderInterface ****

  /// The current [Dataset] being read.  This changes as Sequences are reAD.
  @override
  ByteDataset get currentDS => _currentDS;
  @override
  set currentDS(Dataset ds) => _currentDS = ds;

  /// The current [Element] [Map].
  @override
  Map<int, Element> get currentMap => _currentMap;
  @override
  set currentMap(Map<int, Element> map) => _currentMap = map;

  /// The current duplicate [Element] [Map].
  @override
  Map<int, Element> get currentDupMap => _currentDupMap;
  @override
  set currentDupMap(Map<int, Element> map) => _currentDupMap = map;

  /// Returns an empty [Map<int, Element].
  @override
  Map<int, Element> makeEmptyMap() => <int, Element>{};

  //Urgent: flush or fix
  @override
  Element makeElement(int vrIndex, Tag tag, ByteData bytes,
                          [int vfLength, Uint8List vfBytes]) {
	  int index = (vrIndex == VR.kUN.index) ? tag.vr.index : vrIndex;
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
			  int vfLength,
			  ByteData vfBytes,
		  ]) =>
		  (isEVR)
		  ? EVR.makePixelData(vrIndex, bytes, fragments)
		  : IVR.makePixelData(vrIndex, bytes, fragments);

  /// Returns a new ByteSequence.
  @override
  Element makeSQ(ByteData bd, Dataset parent, List items, int vfLength, bool isEVR) {
	  //TODO: figure out how to create a ByteSequence with one call.
	  Element sq =
	  (isEVR) ? EVR.makeSQ(bd, currentDS, items) : IVR.makeSQ(bd, currentDS, items);
	  for (ByteItem item in items) item.addSQ(sq);
	  return sq;
  }

  /// Returns a new [ByteItem].
  @override
  ByteItem makeItem(ByteData bd, Dataset parent, int vfLength, Map<int, Element> map,
                    [Map<int, Element> dupMap]) =>
		  new ByteItem.fromDecoder(bd, parent, vfLength, map, dupMap);

  @override
  String itemInfo(ByteItem item) => (item == null) ? 'Item item = null' : item.info;

  // **** End DcmReaderInterface ****

  RootByteDataset readFMI({bool checkPreamble = false, bool allowMissingPrefix = false}) {
    bool hadFmi =
        dcmReadFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
    rootDS.parseInfo = getParseInfo();
    return (hadFmi) ? rootDS : null;
  }

  /// Reads a [RootByteDataset] from [this], stores it in [rootDS],
  /// and returns it.
  RootByteDataset readRootDataset(
      {bool allowMissingFMI = false,
      bool checkPreamble = true,
      bool allowMissingPrefix = false}) {
    try {
      var rds = dcmReadRootDataset(
          allowMissingFMI: allowMissingFMI,
          checkPreamble: checkPreamble,
          allowMissingPrefix: allowMissingPrefix);
      if (rds == null) return null;
      rootDS.parseInfo = getParseInfo();
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
    rootDS.bd = bdRead;
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

  //Urgent: flush or fix
  static TagElement makeTagElement(Element be) => be.tagElementFromBytes;

  //Urgent: flush or fix
  static TagElement makeTagPixelData(Element e) {
    assert(e.code == kPixelData);
    print('makePixelData: ${e.info}');
    if (e.vr == VR.kOB)
      return new OBPixelData.fromBytes(e.tag, e.vfBytes, e.vfLength, e.fragments);
    if (e.vr == VR.kOW)
      return new OWPixelData.fromBytes(e.tag, e.vfBytes, e.vfLength, e.fragments);
    if (e.vr == VR.kOB)
      return new UNPixelData.fromBytes(e.tag, e.vfBytes, e.vfLength, e.fragments);
    print('makePixelData: ${e.info}');
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
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    RootByteDataset rds;
    try {
      ByteData bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
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
      TransferSyntax targetTS,
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
      TransferSyntax targetTS,
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
      TransferSyntax targetTS,
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
