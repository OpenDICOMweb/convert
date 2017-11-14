// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readEvrRootDataset(RootDataset rds) {
  _cds = rds;
  return __readRootDataset(_readEvrElement);
}

/// Read a Short EVR Element, i.e. one with a 16-bit
/// Value Field Length field. These Elements may not have
/// a kUndefinedLength value.
Element _readEvrShort(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint16;
  _rb + vlf;
  log.debug(
      '${_rb.rmm} readEvrShort ${dcm(
						code)} vr($vrIndex) '
      '$eStart + 8 + $vlf = ${eStart + 8 + vlf}',
      1);
  _pInfo.nShortElements++;
  return _makeElement(code, eStart, vrIndex, vlf, EvrShort.make);
}

/// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
/// but that cannot have the value kUndefinedValue.
///
/// Reads one of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
Element _readEvrLong(int code, int eStart, int vrIndex) {
  _rb + 2;
  final vlf = _rb.uint32;
  assert(vlf != kUndefinedLength);
  return __readDefinedLength(code, eStart, vrIndex, vlf, EvrLong.make);
}

/// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
/// that might have a value of kUndefinedValue.
///
/// Reads one of OB, OW, and UN.
//  If the Element if UN then it maybe a Sequence.  If it is it will
//  start with either a kItem delimiter or if it is an empty undefined
//  Sequence it will start with a kSequenceDelimiter.
Element _readEvrMaybeUndefined(int code, int eStart, int vrIndex) {
  _rb + 2;
  final vlf = _rb.uint32;
  return __readMaybeUndefinedLength(
      code, eStart, vrIndex, vlf, EvrLong.make, _readEvrElement);
}

/// Read and EVR Sequence.
Element _readEvrSQ(int code, int eStart) {
  _rb + 2;
  final vlf = _rb.uint32;
  return __readSQ(code, eStart, vlf, EvrLong.make, _readEvrElement);
}

int __lookupEvrVRIndex(int code, int eStart, int vrCode) {
  final vr = VR.lookupByCode(vrCode);
  if (vr == null) {
    log.debug('${_rb.rmm} ${dcm(
					code)} $eStart ${hex16(
					vrCode)}');
    _rb.warn('VR is Null: vrCode(${hex16(
					vrCode)}) '
        '${dcm(
					code)} start: $eStart ${_rb.rrr}');
    _showNext(_rb.rIndex - 4);
  }
  return __vrToIndex(code, vr);
}

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElement() {
  _elementCount++;
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final tag = __checkCode(code, eStart);
  final vrCode = _rb.uint16;
  final vrIndex = __lookupEvrVRIndex(code, eStart, vrCode);
  int newVRIndex;

  log.debug(
      '${_rb.rbb} #$_elementCount readEvr ${dcm(
						code)} VR($vrIndex) @$eStart',
      1);

  // Note: this is only relevant for EVR
  if (tag != null) {
    if (_dParams.doCheckVR && __isNotValidVR(code, vrIndex, tag)) {
      final vr = VR.lookupByCode(vrCode);
      log.error('VR $vr is not valid for $tag');
    }

    if (_dParams.doCorrectVR) {
      final oldIndex = vrIndex;
      //Urgent: implement replacing the VR, but must be after parsing
      newVRIndex = __correctVR(code, vrIndex, tag);
      if (vrIndex != oldIndex) {
        final oldVR = VR.lookupByCode(vrCode);
        final newVR = tag.vr;
        log.info1('** Changing VR from $oldVR to $newVR');
      }
    }
  }

  //Urgent: implement correcting VR
  Element e;
  if (_isEvrShortVR(vrIndex)) {
    e = _readEvrShort(code, eStart, vrIndex);
    log.up;
  } else if (_isSequenceVR(vrIndex)) {
    e = _readEvrSQ(code, eStart);
  } else if (_isEvrLongVR(vrIndex)) {
    e = _readEvrLong(code, eStart, vrIndex);
    log.up;
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
    e = _readEvrMaybeUndefined(code, eStart, vrIndex);
    log.up;
  } else {
    return invalidVRIndexError(vrIndex);
  }

  // Elements are always read into the current dataset.
  // **** This is the only place they are added to the dataset.
  final ok = _cds.tryAdd(e);
  if (!ok) log.warn('*** duplicate: $e');

  if (_statisticsEnabled) _doEndOfElementStats(code, eStart, e, ok);
  log.debug('${_rb.ree} readEvr $e', -1);
  return e;
}
