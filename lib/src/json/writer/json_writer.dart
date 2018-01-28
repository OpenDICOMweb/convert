// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/bytes/bytes.dart';
import 'package:convert/src/bytes/buffer/write_buffer.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

typedef void JsonEWriter(Element e);
const int kDefaultJsonWriteBufferLength = 512 * 1024 * 1024;
/// A [class] for writing a [BDRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class JsonWriter {
  final RootDataset rds;
  final String path;
  final bool overwrite;
  final EncodingParameters eParams;
  final TransferSyntax outputTS;
  final int minLength;
//  final ElementOffsets inputOffsets;
  final bool reUseBD;
  final bool doLogging;
  final bool showStats;
//  ElementOffsets outputOffsets;
  final WriteBuffer wb;
  Dataset cds;

  /// Creates a new [JsonWriter] where index = 0.
  JsonWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minLength = kDefaultJsonWriteBufferLength,
//      this.inputOffsets,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats = false})
      : wb = new WriteBuffer(minLength),
        cds = rds;

  /// Writes the [BDRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory JsonWriter.toFile(RootDataset ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
//      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkFile(file, overwrite: overwrite);
    return new JsonWriter(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
//        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new empty [File] from [path], writes the [BDRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory JsonWriter.toPath(RootDataset ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    return new JsonWriter(ds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
//        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new [JsonWriter] where index = 0.
  JsonWriter._(this.rds,
             {this.path = '',
               this.eParams = EncodingParameters.kNoChange,
               this.outputTS,
               this.overwrite = false,
               this.minLength = kDefaultJsonWriteBufferLength,
//               this.inputOffsets,
               this.reUseBD = true,
               this.doLogging = true,
               this.showStats = false})
      : wb = new WriteBuffer(),
        cds = rds;


  bool _isFmiWritten  = false;
  /// Writes a [RootDataset] to a [Uint8List], then returns it.

  Bytes writeRootDataset() {
    if (!_isFmiWritten) writeFmi();
    return writeRootDataset();
  }

  // **** External interface for debugging and monitoring


  static String _jsonEncodeElement<V>(Element e, String vfEncoder(Element e)) =>
      '''
  {
    "${e.hex}": {
      "vr": "${e.vrId}",
      "Value": ${vfEncoder(e)}
    }
  }
''';


  static void _writeFloat(Element e) =>
      _jsonEncodeElement<double>(e, stringFromFloatList);

  static String stringFromFloatList(Element e) {
    assert(e is FloatBase);
    final v = e.values;
    final nList = new List<String>(v.length);
    for(var i = 0; i < v.length; i++)
      nList[i] = '"${floatToString(v.elementAt(i))}"';
    return '[${nList.join(', ')}]';
  }

  static void _writeInt(Element e) =>
      _jsonEncodeElement<int>(e,  stringFromIntList);

  static String stringFromIntList(Element e) {
    assert(e is IntBase);
    return '[${e.values.join(', ')}]';
  }

  static void _writeString(Element e) =>
    _jsonEncodeElement<String>(e, stringFromStringList);

  static String stringFromStringList(Element e) {
    assert(e is StringBase);
    final v = e.values;
    final nList = new List<String>(v.length);
    for(var i = 0; i < v.length; i++)
      nList[i] = '"${v.elementAt(i)}"';
    return '[${nList.join(', ')}]';
  }

 static void _writeText<String>(Element e) =>
      _jsonEncodeElement<String>(e, stringFromStringList);



  // **** Write File Meta Information (FMI) ****

  /// Writes (encodes) only the FMI in the [RootDataset] in 'application/dicom'
  /// media type, writes it to a [Uint8List], and returns that list.
  /// Writes File Meta Information (FMI) to the output.
  /// _Note_: FMI is always Explicit Little Endian
  Uint8List writeFmi() {
    //  if (encoding.doUpdateFMI) return writeODWFMI();
    if (rds is! RootDataset) log.error('Not _rootDS');
    if (!rds.hasFmi) {
      final pInfo = rds.pInfo;
      assert(pInfo.hadPrefix == false || !eParams.doAddMissingFMI);
      log.warn('Root Dataset does not have FMI: $rds');
      if (!eParams.allowMissingFMI || !eParams.doAddMissingFMI) {
        log.error('Dataset $rds is missing FMI elements');
        return kEmptyUint8List;
      }
      if (eParams.doUpdateFMI) return writeOdwFmi(rds);
    }
    assert(rds.hasFmi);
    writeExistingFmi(rds, cleanPreamble: eParams.doCleanPreamble);
    return wb.asUint8List(0, wb.wIndex);
  }


  static void _writeOther(Element e) {

  }

  static void writePixelData(Element e) {

  }

  static void writeSequence(Element e) {

  }
  static void writeElement(Element e) => _jsonWriters[e.vrIndex](e);

  static final List<JsonEWriter> _jsonWriters = <JsonEWriter>[
    _sqError, // stop reformat
    // Maybe Undefined Lengths
    _writeOther, _writeOther, _writeOther,

    // EVR Long
    _writeOther, _writeOther, _writeOther,
    _writeString, _writeText, _writeText,

    // EVR Short

    _writeString, _writeString, _writeInt,
    _writeString, _writeString, _writeString,
    _writeString, _writeFloat, _writeFloat,
    _writeString, _writeString, _writeText,
    _writeString, _writeString, _writeInt,
    _writeInt, _writeText, _writeString,
    _writeString, _writeInt, _writeInt,
  ];

/*
  static final List<JsonWriter> _JsonWriters = <JsonWriter>[
    _sqError, // stop reformat
    // Maybe Undefined Lengths
    writeOther, writeOther, writeOther,

    // EVR Long
    writeOther, writeOther, writeOther,
    UCevr.make, URevr.make, UTevr.make,

    // EVR Short

    AEevr.make, ASevr.make, ATevr.make,
    CSevr.make, DAevr.make, DSevr.make,
    DTevr.make, FDevr.make, FLevr.make,
    ISevr.make, LOevr.make, LTevr.make,
    PNevr.make, SHevr.make, SLevr.make,
    SSevr.make, STevr.make, TMevr.make,
    UIevr.make, ULevr.make, USevr.make,
  ];
*/


  Uint8List writeOdwFmi(RootDataset rootDS) {
    if (rootDS is! RootDataset) log.error('Not rds');
    //Urgent finish
    return wb.asUint8List(0, wb.wIndex);
  }

  void writeExistingFmi(RootDataset rootDS, {bool cleanPreamble = true}) {
    for (var e in rootDS.fmi) {
      assert(e.code >= 0x20000000 && e.code < 0x00030000);
      writeElement(e);
    }
  }

  static Null _sqError(Element e) => invalidElementIndex(e.vrIndex);


  /// Writes the [RootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(RootDataset rds,
                          {String path = '',
                            EncodingParameters eParams,
                            TransferSyntax outputTS,
                            bool overwrite = false,
                            int minLength,
                            ElementOffsets inputOffsets,
                            bool reUseBD = false,
                            bool doLogging = true,
                            bool showStats = false}) {
    checkRootDataset(rds);
    final writer = new JsonWriter(rds,
                                      path: path,
                                      eParams: eParams,
                                      outputTS: outputTS,
                                      overwrite: overwrite,
                                      minLength: minLength,
//                                      inputOffsets: inputOffsets,
                                      reUseBD: reUseBD,
                                      doLogging: doLogging,
                                      showStats: showStats);
    return writer.writeRootDataset();
  }

  /// Writes the [RootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Future<Bytes> writeFile(RootDataset ds, File file,
                                 {EncodingParameters eParams,
                                   TransferSyntax outputTS,
                                   bool overwrite = false,
                                   int minLength,
//                                   ElementOffsets inputOffsets,
                                   bool reUseBD = false,
                                   bool doLogging = true,
                                   bool showStats = false}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
                                 path: file.path,
                                 eParams: eParams,
                                 outputTS: outputTS,
                                 overwrite: overwrite,
                                 minLength: minLength,
//                                 inputOffsets: inputOffsets,
                                 reUseBD: reUseBD,
                                 doLogging: doLogging,
                                 showStats: showStats);
    await file.writeAsBytes(bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Future<Bytes> writePath(RootDataset ds, String path,
                                 {EncodingParameters eParams,
                                   TransferSyntax outputTS,
                                   bool overwrite = false,
                                   int minLength,
//                                   ElementOffsets inputOffsets,
                                   bool reUseBD = false,
                                   bool doLogging = true,
                                   bool showStats = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
                         eParams: eParams,
                         outputTS: outputTS,
                         overwrite: overwrite,
                         minLength: minLength,
//                         inputOffsets: inputOffsets,
                         reUseBD: reUseBD,
                         doLogging: doLogging,
                         showStats: showStats);
  }
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [RootDataset].
class LoggingJsonWriter extends JsonWriter {
  final ParseInfo pInfo;
  final ElementOffsets inputOffsets;
  final ElementOffsets outputOffsets;
  int elementCount;

  /// Creates a new [LoggingJsonWriter], which is encoder for Binary DICOM
  /// (application/dicom).
  LoggingJsonWriter(
      RootDataset rds, EncodingParameters eParams, int minLength, this.inputOffsets,
      {bool reUseBD = false})
      : outputOffsets = (inputOffsets != null) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        super._(rds, eParams: eParams, minLength: minLength, reUseBD: reUseBD);
}


/*
bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isNotShortVR(int vrIndex) => !_isShortVR(vrIndex);
*/

