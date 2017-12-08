// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/base/reader_base.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/binary/base/reader/reader_interface_old.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';

int _elementCount;

abstract class EvrReader extends DcmReaderBase {
  /// Creates a new [DcmReader]  where [rb].rIndex = 0.
  ReaderBase(ByteData bd, RootDataset rds,
      {String path = '', //TODO: make async work and be the
      // default
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange})
      : super(bd, rds, path: path, reUseBD: reUseBD, dParams: dParams);

  RootDataset read() => super.read();

  /// For EVR Datasets, all Elements are read by this method.
  Element readEvrElement() {
    _elementCount++;
    final eStart = rb.rIndex;
    final code = rb.code;
    final tag = checkCode(code, eStart);
    final vrCode = rb.uint16;
    final vrIndex = __lookupEvrVRIndex(code, eStart, vrCode);
    int newVRIndex;

    log.debug(
        '${rb.rbb} #$_elementCount readEvr ${dcm(
						code)} VR($vrIndex) @$eStart',
        1);

    // Note: this is only relevant for EVR
    if (tag != null) {
      final vr = VR.lookupByCode(vrCode);
      log.error('VR $vr is not valid for $tag');
    }

    //Urgent: implement correcting VR
    Element e;
    if (_isEvrShortVR(vrIndex)) {
      e = readEvrShort(code, eStart, vrIndex);
      log.up;
    } else if (_isSequenceVR(vrIndex)) {
      e = readEvrSQ(code, eStart);
    } else if (_isEvrLongVR(vrIndex)) {
      e = readEvrLong(code, eStart, vrIndex);
      log.up;
    } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
      e = readEvrMaybeUndefined(code, eStart, vrIndex);
      log.up;
    } else {
      return invalidVRIndexError(vrIndex);
    }

    // Elements are always read into the current dataset.
    // **** This is the only place they are added to the dataset.
    final ok = _cds.tryAdd(e);
    if (!ok) log.warn('*** duplicate: $e');

    if (_statisticsEnabled) _doEndOfElementStats(code, eStart, e, ok);
    log.debug('${rb.ree} readEvr $e', -1);
    return e;
  }

  int __lookupEvrVRIndex(int code, int eStart, int vrCode) {
    final vr = VR.lookupByCode(vrCode);
    if (vr == null) {
      log.debug('${rb.rmm} ${dcm(
							code)} $eStart ${hex16(
							vrCode)}');
      rb.warn('VR is Null: vrCode(${hex16(
							vrCode)}) '
          '${dcm(
							code)} start: $eStart ${rb.rrr}');
      _showNext(rb.rIndex - 4);
    }
    return __vrToIndex(code, vr);
  }

  /// Read a Short EVR Element, i.e. one with a 16-bit
  /// Value Field Length field. These Elements may not have
  /// a kUndefinedLength value.
  Element readEvrShort(int code, int eStart, int vrIndex) {
    final vlf = rb.uint16;
    rb + vlf;
    log.debug(
        '${rb.rmm} readEvrShort ${dcm(
						code)} vr($vrIndex) '
        '$eStart + 8 + $vlf = ${eStart + 8 + vlf}',
        1);
    pInfo.nShortElements++;
    return _makeElement(code, eStart, vrIndex, vlf, EvrShort.make);
  }

  /// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// but that cannot have the value kUndefinedValue.
  ///
  /// Reads one of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
  Element readEvrLong(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    assert(vlf != kUndefinedLength);
    return readLongDefinedLength(code, eStart, vrIndex, vlf, EvrLong.make);
  }

  /// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
  /// that might have a value of kUndefinedValue.
  ///
  /// Reads one of OB, OW, and UN.
  //  If the Element if UN then it maybe a Sequence.  If it is it will
  //  start with either a kItem delimiter or if it is an empty undefined
  //  Sequence it will start with a kSequenceDelimiter.
  Element readEvrMaybeUndefined(int code, int eStart, int vrIndex) {
    rb + 2;
    final vlf = rb.uint32;
    return readMaybeUndefinedLength(
        code, eStart, vrIndex, vlf, EvrLong.make, readEvrElement);
  }

  /// Read and EVR Sequence.
  Element readEvrSQ(int code, int eStart) {
    rb + 2;
    final vlf = rb.uint32;
    return readSQ(code, eStart, vlf, EvrLong.make, readEvrElement);
  }
}
