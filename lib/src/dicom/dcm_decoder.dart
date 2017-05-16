// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:core/core.dart';

import 'dcm_reader.dart';

/// Decoder for DICOM File Format octet streams (Uint8List)

/// [DcmDecoder] reads DICOM SOP Instances and returns a [RootDataset].
/// TODO: finish doc
class DcmDecoder extends DcmReader {
  static final Logger log = new Logger("DcmDecoder", watermark: Severity.info);
  //TODO: add ability to keep non-zero preamble

  /// The source of the bytes to be parsed.
  final DSSource source;

  /// Creates a new [DcmDecoder]
  DcmDecoder(Uint8List bytes,
      {String path = "", bool throwOnError = false, bool allowILEVR = true})
      : source = null,
        super(bytes,
            path: path, throwOnError: throwOnError, allowILEVR: allowILEVR);

  /// Creates a new [DcmDecoder]
  DcmDecoder.fromSource(this.source,
      {String path = "", bool throwOnError = false, bool allowILEVR = true})
      : super(source.bytes,
            path: path, throwOnError: throwOnError, allowILEVR: allowILEVR);
/*
  // Read the 128-byte preamble to the DICOM File Format.
  Uint8List readPreamble() {
    _preamble = readUint8List(128);
    return _preamble;
  }

  //TODO: move to a utilities file for TypedData
  static bool hasAllZeros(Uint8List preamble) {
    for (int i = 0; i < preamble.length; i++)
      if (preamble[i] != 0) return false;
    return true;
  }

  // Reads the DICOM Prefix "DICM" and returns [null] if not present.
  // The Prefix is equivalent to a magic number that specifies the [Uint8List] is
  // in DICOM File Format. See PS3.10.
  //TODO: is this really needed?
  String readPrefix() {
    String prefix = readString(4);
    if (prefix != "DICM") {
      throw 'Bad Prefix: $prefix';
    }
    _prefix = prefix;
    return _prefix;
  }
*/
  //TODO: this will need to be modified to handle different types of datasets
  //TODO for now they are all instances.
  /// Reads a DICOM SOP [Instance] from a [Uint8List].
  Entity readInstance([Series series, Study study, Subject subject]) {
    log.debug('readInstance: $this');
    log.down;
    RootDataset ds;
    //   try {
    ds = readRootDataset();
    //   } catch (e) {
    //     log.error('readInstance: $e');
    //     return null;
    //   }
    if (!ds.hasValidTransferSyntax) return null;
    log.debug('readInstance RootDataset($ds)');
    return new Instance.fromDataset(ds, series, study, subject);
  }

  //TODO: this will need to be modified to handle different types of datasets
  //TODO for now they are all instances.
  /// Reads a DICOM SOP [Instance] from a [Uint8List].
  RootDataset readRDS() {
    log.debug('readRDS: $this');
    log.down;
    RootDataset ds;

    ds = readRootDataset();
    if (!ds.hasValidTransferSyntax) return null;

    log.debug('readRDS: count(${ds.length})');
    return ds;
  }

  ///TODO: doc
  static Instance decode(DSSource source,
      [Series series, Study study, Subject subject]) {
    DcmDecoder decoder = new DcmDecoder.fromSource(source);
    return decoder.readInstance(series, study, subject);
  }

  static RootDataset readRoot(Uint8List bytes) {
    DcmDecoder decoder = new DcmDecoder(bytes);
    RootDataset rds = decoder.readRootDataset();
    return rds;
  }

  static RootDataset readRootNoFMI(Uint8List bytes) {
    DcmDecoder decoder = new DcmDecoder(bytes);
    Dataset rds = decoder.readDataset();
    return rds;
  }

  static RootDataset readFile(File file) {
    var bytes = file.readAsBytesSync();
    return DcmDecoder.readRoot(bytes);
  }
}
