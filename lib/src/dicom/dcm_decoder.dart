// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'dcm_reader.dart';

/// Decoder for DICOM File Format octet streams (Uint8List)

/// [DcmDecoder] reads DICOM SOP Instances and returns a [RootDataset].
/// TODO: finish doc
class DcmDecoder extends DcmReader {
  static final Logger log = new Logger("DcmDecoder", logLevel: Level.info);
  //TODO: add ability to keep non-zero preamble
  Uint8List _preamble;
  String _prefix;
  bool allowImplicitLittleEndian = true;

  /// Creates a new [DcmDecoder]
  DcmDecoder(DSSource source)
      : //rootDS = new RootDataset(source),
        super(source);

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

  //TODO: this will need to be modified to handle different types of datasets
  //TODO for now they are all instances.
  /// Reads a DICOM SOP [Instance] from a [Uint8List].
  Entity readInstance([Study study]) {
    log.debug('readInstance: $this');
    log.down;
    RootDataset ds = readRootDataset();
    if (!ds.hasValidTransferSyntax) return null;
    ds.format(new Formatter());
    log.debug('RootDataset($ds)');
    if (study == null) {
      String id = ds.patientId;
      //TODO
      //Patient patient = new Patient.fromDataset(id, ds);
      Patient patient = new Patient(null, ds, id, <Uid, Study>{});
      Uid studyUid = ds.studyUid ?? "Null Instance Uid";
      study = new Study.fromDataset(patient, studyUid, ds);
    }
    Uid seriesUid = ds.seriesUid ?? "Null Instance Uid";
    Series series = new Series.fromDataset(study, seriesUid, ds);
    Uid instanceUid = ds.instanceUid ?? "Null Instance Uid";
    Instance instance = new Instance.fromDataset(series, instanceUid, ds);
    log.up;
    log.debug(instance);
    return instance;
  }

  ///TODO: doc
  static Instance decode(DSSource source, [Study study]) {
    DcmDecoder decoder = new DcmDecoder(source);
    return decoder.readInstance(study);
  }
}
