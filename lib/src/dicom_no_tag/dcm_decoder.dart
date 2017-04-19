// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/entity.dart';

import 'dataset.dart';
import 'dcm_reader.dart';

/// Decoder for DICOM File Format octet streams (Uint8List)

/// [DcmDecoder] reads DICOM SOP Instances and returns a [RootDataset].
/// TODO: finish doc
class DcmDecoder extends DcmReader {
  //TODO: add ability to keep non-zero preamble

  /// Creates a new [DcmDecoder]
  DcmDecoder(ByteData bd,
      {bool throwOnError = true,
      String path = "",
      bool allowImplicitLittleEndian = true})
      : super(bd,
            throwOnError: throwOnError,
            path: path,
            allowImplicitLittleEndian: allowImplicitLittleEndian);

  /// Creates a new [DcmDecoder]
  //  Fix: DcmDecoder.fromSource([this.source = DSSource.kUnknown])
  //    : super.fromSource(source, new RootDataset());
/*
  // Read the 128-byte preamble to the DICOM File Format.
  Uint8List _readPreamble() {
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
  String _readPrefix() {
    skip(128);
    String prefix = readString(4);
    if (prefix != "DICM") {
      throw 'Bad Prefix: $prefix';
    }
    _prefix = prefix;
    return _prefix;
  }
*/
/* fix or flush
  //TODO: this will need to be modified to handle different types of datasets
  //TODO for now they are all instances.
  /// Reads a DICOM SOP [Instance] from a [Uint8List].
  Entity readInstance([Series series, Study study, Subject subject]) {
    DcmReader.log.debug('readInstance: $this');
    DcmReader.log.down;
    RootDataset ds;
 //   try {
      ds = readRootDataset();
 //   } catch (e) {
 //     DcmReader.log.error('readInstance: $e');
 //     return null;
 //   }
    if (!ds.hasValidTransferSyntax) return null;
    DcmReader.log.debug('readInstance RootDataset($ds)');
    return Instance.fromDataset(ds, series, study, subject);
  }
*/
  //TODO: this will need to be modified to handle different types of datasets
  //TODO for now they are all instances.
  /// Reads a DICOM SOP [Instance] from a [Uint8List].
  RootDataset readRDS() {
    DcmReader.log.debug('readRDS: $this');
    DcmReader.log.down;
    RootDataset ds;

    ds = readRootDataset();
    if (!ds.hasValidTransferSyntax) return null;

    DcmReader.log.debug('readRDS: count(${ds.length})');
    return ds;
  }

  static RootDataset readRoot(Uint8List bytes) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmDecoder decoder = new DcmDecoder(bd);
    RootDataset rds = decoder.readRootDataset();
    return rds;
  }

  static RootDataset readRootNoFMI(Uint8List bytes) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmDecoder decoder = new DcmDecoder(bd);
    Dataset rds = decoder.xReadDataset();
    return rds;
  }

  static RootDataset readFile(File file) {
    var bytes = file.readAsBytesSync();
    return DcmDecoder.readRoot(bytes);
  }
}
