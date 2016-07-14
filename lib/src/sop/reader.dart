// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.convert.sop.reader;

import 'dart:io';
import 'dart:typed_data';

import 'package:logger/server_logger.dart';

import 'package:odwsdk/attribute.dart';
import 'package:odwsdk/dataset_sop.dart';
import 'package:odwsdk/tag.dart';
import 'package:odwsdk/uid.dart';

import '../dcmbuf/dcmbuf.dart';

/// [DcmReader] reads DICOM SOP Instances and returns a [DatasetSop].
/// TODO: finish doc
class DcmReader extends DcmBuf {
  static final Logger log = new Logger("DcmReader", Level.info);
  Uint8List _preamble;
  String _prefix;

  /// Creates a new [DcmReader]
  factory DcmReader(Uint8List bytes, [int readIndex = 0, int writeIndex, int lengthInBytes]) {
    if (lengthInBytes == null) lengthInBytes = bytes.lengthInBytes - readIndex;
    if (writeIndex == null) writeIndex = lengthInBytes;
    return new DcmReader._(bytes, readIndex, writeIndex, lengthInBytes);
  }

  factory DcmReader.fromFile(file) {
    if (file is String) file = new File(file);
    if (file is! File) {
      log.error('The "file" parameter must be a String or File');
      return null;
    }
    var bytes = file.readAsBytesSync();
    return new DcmReader(bytes);
  }

  factory DcmReader.fromUint8List(Uint8List bytes) =>
    new DcmReader(bytes, 0, bytes.length, bytes.length);

  /// Internal Constructor: Returns a [._slice from [bytes].
  DcmReader._(Uint8List bytes, int readIndex, int writeIndex, int length)
      : super.internal(bytes, readIndex, writeIndex, length);

  // Read the 128-byte preamble to the DICOM File Format.
  Uint8List readPreamble() => _preamble = readUint8List(128);


  // Reads the DICOM Prefix "DICM" and returns [null] if not present.
  // The Prefix is equivalent to a magic number that specifies the [Uint8List] is
  // in DICOM File Format. See PS3.10.
  String readPrefix() {
    var prefix = readString(4);
    if (prefix != "DICM") {
      log.warning('Bad Prefix: $prefix');
      setReadIndex(0);
      return null;
    }
    _prefix = prefix;
    return prefix;
  }

  /// Reads and returns the File Meta Information [Fmi], if present. If no [Fmi] [Attributes]
  /// were present an empty [Map] is returned.
  Fmi readFmi() {
    Map<int, Attribute> fmi = {};
    while(isFmiTag()) {
      var a = readAttribute();
      log.debug('$a');
      fmi[a.tag] = a;
    }
    return new Fmi(fmi);
  }

  Study readSopInstance([Study study]) {
    Logger log = new Logger("DcmReader.readSopInstance");
    _preamble = readPreamble();
    _prefix = readPrefix();
    if (_prefix == null) return null;
    var fmi = readFmi();
    var aMap = readDataset();

    var studyUid = aMap[kStudyInstanceUID].value;
    if (study == null) {
      study = new Study(studyUid);
    }
    study.createInstance(fmi, aMap);
    return study;
  }

  Map readDatase(DcmBuf buf) {
    final Logger log = new Logger("DS", Level.debug);
    Map<int, Attribute> aMap = {};


    while (buf.isReadable) {
      Attribute a = buf.readAttribute();
      aMap[a.tag] = a;
      if (a.tag == kPixelData) {
        log.info('PixelData: ${fmtTag(a.tag)}, ${a.vr}, length= ${a.values.length}');
      } else {
        log.info('$a');
      }
    }
    log.info('ByteBuf: $buf');
    return aMap;
  }

  @override
  void debug() {
    print('Preamble: $_preamble');
    print('Prefix: $_preamble');
  }

  //TODO: move to a utilities file for TypedData
  static bool hasAllZeros(Uint8List preamble) {
    for (int i = 0; i < preamble.length; i++)
      if (preamble[i] != 0) return false;
    return true;
  }
}


