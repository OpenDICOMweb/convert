// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readEvrRootDataset() {
	log.reset;
  _isEvr = true;

  log.debug('${_rb.rbb} readEvrRootDataset');
  _readDatasetDefinedLength(_rds, _rb.rIndex, _rb.remaining, _readEvrElement);
  log.debug('${_rb.ree} readEvrRootDataset $_elementCount Elements read with '
      '${_rb.remaining} bytes remaining\nDatasets: ${_pInfo.nDatasets}');
}

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElement() {
	_elementCount++;
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final tag = __checkCode(code, eStart);
  final vrCode = _rb.uint16;
  var vrIndex = __lookupEvrVRIndex(code, eStart, vrCode);

	log.debug('${_rb.rbb} #$_elementCount readEvr ${dcm(code)} VR($vrIndex) @$eStart', 1);

	if (tag != null) {
    if (_dParams.doCheckVR && __isNotValidVR(code, vrIndex, tag)) {
      final vr = VR.lookupByCode(vrCode);
      log.error('VR $vr is not valid for $tag');
    }

    if (_dParams.doCorrectVR) {
      final oldIndex = vrIndex;
      vrIndex = __correctVR(code, vrIndex, tag);
      if (vrIndex != oldIndex) {
        final oldVR = VR.lookupByCode(vrCode);
        final newVR = tag.vr;
        log.warn('** Changing VR from $oldVR to $newVR');
      }
    }
  }

  Element e;
  if (  _isEvrShortVR(vrIndex)) {
    _pInfo.nShortElements++;
    e = _readEvrShort(code, eStart, vrIndex);
    log.up;
  } else if (_isSequenceVR(vrIndex)) {
    e = _readEvrSQ(code, eStart);
  } else if (_isEvrLongVR(vrIndex)) {
    _pInfo.nLongElements++;
    e = _readEvrLong(code, eStart, vrIndex);
    log.up;
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
    _pInfo.nMaybeUndefinedElements++;
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

int __lookupEvrVRIndex(int code, int eStart, int vrCode) {
  final vr = VR.lookupByCode(vrCode);
  if (vr == null) {
    _rb.warn('VR is Null: vrCode(${hex16(vrCode)}) '
        '${dcm(code)} start: $eStart ${_rb.rrr}');
    _showNext(_rb.rIndex - 4);
  }
  return __vrToIndex(code, vr);
}

/// Read a Short EVR Element, i.e. one with a 16-bit
/// Value Field Length field. These Elements may not have
/// a kUndefinedLength value.
Element _readEvrShort(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint16;
  _rb + vlf;
  log.debug('${_rb.rmm} readEvrShort ${dcm(code)} vr($vrIndex) '
		            '$eStart + 8 + $vlf = ${eStart + 8 + vlf}', 1);
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
  log.debug('${_rb.rmm} readEvrLong ${dcm(code)} vr($vrIndex) '
		            '$eStart + 12 + $vlf = ${eStart + 12 + vlf}', 1);
  return __readEvrLongDefinedLength(code, eStart, vrIndex, vlf);
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
  log.debug('${_rb.rbb} readEvrMaybeUndefined ${dcm(code)} vr($vrIndex) '
		            '$eStart + 12 + ??? = ???', 1);

  // If VR is UN then this might be a Sequence
  if (vrIndex == kUNIndex) {
    final e = __tryReadUNSequence(code, eStart, vlf, EvrLong.make, _readEvrElement);
    if (e != null) return e;
  }
  return (vlf == kUndefinedLength)
      ? __readEvrUndefinedLength(code, eStart, vrIndex, vlf)
      : __readEvrLongDefinedLength(code, eStart, vrIndex, vlf);
}

/// Read and EVR Sequence.
Element _readEvrSQ(int code, int eStart) {
	final eNumber = _elementCount;
  _rb + 2;
  final vlf = _rb.uint32;
	log.debug('${_rb.rbb} #$eNumber readEvrSQ ${dcm(code)} @$eStart vfl:$vlf', 1);
  final e =  __readSQ(code, eStart, vlf, EvrLong.make, _readEvrElement);
  log.debug('${_rb.ree} #$eNumber readEvrSQ ${dcm(code)} $e', -1);
  return e;
}

// Finish reading an EVR Long Defined Length Element
Element __readEvrLongDefinedLength(int code, int eStart, int vrIndex, int vlf) {
  assert(vlf != kUndefinedLength);
  log.debug('${_rb.rmm} readEvrLongDefined ${dcm(code)} vr($vrIndex) '
		            '$eStart + 12 + $vlf = ${eStart + 12 + vlf}');
  _pInfo.nDefinedLengthElements++;
  _rb + vlf;
  return (code == kPixelData)
      ? _makePixelData(code, eStart, vrIndex, _rb.rIndex, false, EvrLong.make)
      : _makeElement(code, eStart, vrIndex, _rb.rIndex, EvrLong.make);
}

// Finish reading an EVR Long Undefined Length Element
Element __readEvrUndefinedLength(int code, int eStart, int vrIndex, int vlf) {
  assert(vlf == kUndefinedLength);
  log.debug('${_rb.rmm} readEvrLongUndefined ${dcm(code)} vr($vrIndex) '
		            '$eStart + 12 + ??? = ???');
  _pInfo.nUndefinedLengthElements++;
  if (code == kPixelData) {
    return __readEncapsulatedPixelData(code, eStart, vrIndex, vlf, EvrLong.make);
  } else {
    final endOfVF = _findEndOfULengthVF();
    return _makeElement(code, eStart, vrIndex, endOfVF, EvrLong.make);
  }
}
