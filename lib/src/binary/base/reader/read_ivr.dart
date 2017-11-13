// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readIvrRootDataset() {
  _isEvr = false;

  log.debug('${_rb.rbb} readIvrRootDataset: ${_rb.remaining}');
  _readDatasetDefinedLength(_rds, _rb.rIndex, _rb.remaining, _readIvrElement);
  log.debug('${_rb.ree} readIvrRootDataset $_elementCount Elements read with '
      '${_rb.remaining} bytes remaining\nDatasets: ${_pInfo.nDatasets}');
}

/// All [Element]s are read by this method.
Element _readIvrElement() {
	_elementCount++;
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final tag = __checkCode(code, eStart);
  final vrIndex = __lookupIvrVRIndex(code, eStart, tag);

	log.debug('${_rb.rbb} #$_elementCount readIvr ${dcm(code)} VR($vrIndex) @$eStart', 1);

	Element e;
  if (_isIvrDefinedLengthVR(vrIndex)) {
	  _pInfo.nLongElements++;
    e = _readIvrDefinedLength(code, eStart, vrIndex);
    log.up;
  } else if (vrIndex == kVRIndexMin) {
    e = _readIvrSQ(code, eStart);
    log.up;
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
	  _pInfo.nMaybeUndefinedElements++;
    e = _readIvrMaybeUndefinedLength(code, eStart, vrIndex);
    log.up;
  } else {
    return invalidVRIndexError(vrIndex);
  }

	// Elements are always read into the current dataset.
	// **** This is the only place they are added to the dataset.
	final ok = _cds.tryAdd(e);
	if (!ok) log.warn('*** duplicate: $e');

	if (_statisticsEnabled) _doEndOfElementStats(code, eStart, e, ok);
	log.debug('${_rb.ree} readIvr $e', -1);
	return e;
}

int __lookupIvrVRIndex(int code, int eStart, Tag tag) {
	final vr = (tag == null) ? VR.kUN : tag.vr;
	return __vrToIndex(code, vr);
}

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField (vlf),
/// but that cannot have kUndefinedValue.
Element _readIvrDefinedLength(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint32;
  assert(vlf != kUndefinedLength);
  log.debug('${_rb.rmm} readIvrDefinedLength ${dcm(code)} vr($vrIndex) '
		            '$eStart + 12 + $vlf = ${eStart + 12 + vlf}', 1);
  return __readIvrDefinedLength(code, eStart, vrIndex, vlf);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefinedLength(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint32;
  log.debug('${_rb.rbb} _readIvrMaybeUndefinedLength ${dcm(code)} vr($vrIndex) '
		            '$eStart + 12 + ??? = ???', 1);

  // If VR is UN then this might be a Sequence
  if (vrIndex == kUNIndex) {
	  final e = __tryReadUNSequence(code, eStart, vlf, EvrLong.make, _readEvrElement);
	  if (e != null) return e;
  }
  return (vlf == kUndefinedLength)
      ? __readIvrUndefinedLength(code, eStart, vrIndex, vlf)
      : __readIvrDefinedLength(code, eStart, vrIndex, vlf);
}

Element _readIvrSQ(int code, int eStart) {
  final vlf = _rb.uint32;
  final eNumber = _elementCount;
  log.debug('${_rb.rbb} #$eNumber readEvrSQ ${dcm(code)} @$eStart vfl:$vlf', 1);
  final e = __readSQ(code, eStart, vlf, Ivr.make, _readIvrElement);
  log.debug('${_rb.ree} #$eNumber readEvrSQ ${dcm(code)} $e', -1);
  return e;
}

/// Read an IVR Element (not SQ) with a 32-bit [vlf], but that cannot
/// have kUndefinedValue.
Element __readIvrDefinedLength(int code, int eStart, int vrIndex, int vlf) {
	assert(vlf != kUndefinedLength);
	log.debug('${_rb.rmm} readIvrLongDefined ${dcm(code)} vr($vrIndex) '
			          '$eStart + 12 + $vlf = ${eStart + 12 + vlf}');
	_pInfo.nDefinedLengthElements++;
	_rb + vlf;
	return (code == kPixelData)
	       ? _makePixelData(code, eStart, vrIndex, _rb.rIndex, false, Ivr.make)
	       : _makeElement(code, eStart, vrIndex, _rb.rIndex, Ivr.make);
}

/// Read an Element (not SQ)  that has an undefined length.
Element __readIvrUndefinedLength(int code, int eStart, int vrIndex, int vlf) {
	log.debug('${_rb.rmm} readIvrUndefinedLength ${dcm(code)} vr($vrIndex) '
			          '$eStart + 12 + ??? = ???');
	_pInfo.nUndefinedLengthElements++;
	if (code == kPixelData) {
		return __readEncapsulatedPixelData(code, eStart, vrIndex, vlf, Ivr.make);
	} else {
		final endOfVF = _findEndOfULengthVF();
		return _makeElement(code, eStart, vrIndex, endOfVF, Ivr.make);
	}
}



