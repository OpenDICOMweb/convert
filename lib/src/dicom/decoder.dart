// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dcm_convert/src/dicom/decoder_bytebuf.dart';
import 'package:logger/logger.dart';

/// Decoder for DICOM File Format octet streams (Uint8List)

/// [DcmDecoder] reads DICOM SOP Instances and returns a [DatasetSop].
/// TODO: finish doc
class DcmDecoder extends DcmDecoderByteBuf {
  static final Logger log = new Logger("DcmEncoder");
  //TODO: add ability to keep non-zero preamble
  Uint8List _preamble;
  String _prefix;

  /// Creates a new [DcmDecoder]
  factory DcmDecoder(Uint8List bytes, [int readIndex = 0, int writeIndex, int lengthInBytes]) {
    if (lengthInBytes == null) lengthInBytes = bytes.lengthInBytes - readIndex;
    if (writeIndex == null) writeIndex = lengthInBytes;
    return new DcmDecoder.internal(bytes, readIndex, writeIndex, lengthInBytes);
  }

  factory DcmDecoder.fromUint8List(Uint8List bytes) =>
      new DcmDecoder(bytes, 0, bytes.length, bytes.length);

  /// Internal Constructor: Returns a [._slice from [bytes].
  DcmDecoder.internal(Uint8List bytes, int readIndex, int writeIndex, int length)
      : super.internal(bytes, readIndex, writeIndex, length);

  // Read the 128-byte preamble to the DICOM File Format.
  Uint8List readPreamble() {
    _preamble = readUint8List(128);
    if (! hasAllZeros(_preamble)) {
      log.info('Preamble all zeros.');
    } else {
      log.info('Preamble: $_preamble');
    }
    return _preamble;
  }

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

  //static const littleEndian =
  //    WellKnownUid.kImplicitVRLittleEndianDefaultTransferSyntaxforDICOM;

  Instance readSopInstance([String path]) {
    Logger log = new Logger("DcmEncoder.readSopInstance");
    _preamble = readPreamble();
  //  print('preamble: $_preamble');
    _prefix = readPrefix();
  //  print('prefix: $_prefix');
    //TODO: we could try to figure out what it contained later.
    if (_prefix == null) return null;
    Map<int, Element> fmi = readFmi();
  //  print('Fmi: $fmi');

    log.debug('readSopInstance: fmi = $fmi');
    int start = readIndex;
    var eMap = readDataset();
    int lengthInBytes = readIndex - start;
    Dataset ds = new Dataset(fmi, eMap, lengthInBytes, false);

    Instance instance = ActiveStudies.addSopInstance(ds);

  //  print('***${instance.format(new Formatter())}');
    return instance;
  }

  /// Reads and returns the File Meta Information [Fmi], if present. If no [Fmi] [Elements]
  /// were present an empty [Map] is returned.
  Map<int, Element> readFmi() {
    Map<int, Element> fmiMap = {};
    while (isFmiTag()) {
      var a = readElement();
      fmiMap[a.tag] = a;
    }
  ///  print('fmiMap: $fmiMap');
    return fmiMap;
  }

  /// Returns an [Element] or [null].
  ///
  /// This is the top-level entry point for reading a [Dataset].
  Map<int, Element> readDataset() {
    final Logger log = new Logger("readDataset");
    Map<int, Element> deMap = {};
    while (isReadable) {
      Element a = readElement();
      deMap[a.tag] = a;
      if (a.tag == kPixelData) {
        //print('PixelData(${tagToDcm(a.tag)}): ${a.vr}, length= ${a.length}');
        log.debug('PixelData(${tagToDcm(a.tag)}): ${a.vr}, length= ${a.length}');
      } else {
        log.debug('$a');
      }
    }
    log.debug('DcmBuf: $this');
    return deMap;
  }

  //TODO: move to a utilities file for TypedData
  static bool hasAllZeros(Uint8List preamble) {
    for (int i = 0; i < preamble.length; i++)
      if (preamble[i] != 0) return false;
    return true;
  }
}


