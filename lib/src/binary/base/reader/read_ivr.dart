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

  _rb.sMsg('readIvrElement', code, eStart, vrIndex);
  Element e;
  if (_isIvrDefinedLengthVR(vrIndex)) {
	  _pInfo.nLongElements++;
    e = _readIvrDefinedLength(code, eStart, vrIndex);
  } else if (vrIndex == kVRIndexMin) {
    e = _readIvrSQ(code, eStart);
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
	  _pInfo.nMaybeUndefinedElements++;
    e = _readIvrMaybeUndefinedLength(code, eStart, vrIndex);
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
  _rb.sMsg('_readIvrDefinedLength', code, eStart, vrIndex, 8, vlf);
  return __readIvrDefinedLength(code, eStart, vrIndex, vlf);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefinedLength(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint32;
  _rb.mMsg('readIvrMaybeUndefined', code, eStart, vrIndex, 8, vlf);

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
  _rb.sMsg('readIvrSQ', code, eStart, kSQIndex, 8, vlf);
  return __readSQ(code, eStart, vlf, Ivr.make, _readIvrElement);
}

/// Read an IVR Element (not SQ) with a 32-bit [vlf], but that cannot
/// have kUndefinedValue.
Element __readIvrDefinedLength(int code, int eStart, int vrIndex, int vlf) {
	assert(vlf != kUndefinedLength);
	_rb.mMsg('readIvrDefined', code, eStart, vrIndex, 8, vlf);
	_pInfo.nDefinedLengthElements++;
	_rb + vlf;

	return (code == kPixelData)
	       ? _makePixelData(code, eStart, vrIndex, _rb.rIndex, false, Ivr.make)
	       : _makeElement(code, eStart, vrIndex, _rb.rIndex, Ivr.make);
}

/// Read an Element (not SQ)  that has an undefined length.
Element __readIvrUndefinedLength(int code, int eStart, int vrIndex, int vlf) {
	_rb.sMsg('readIvrUndefined', code, eStart, vrIndex, 8, vlf);
	_pInfo.nUndefinedLengthElements++;
	if (code == kPixelData) {
		return __readEncapsulatedPixelData(code, eStart, vrIndex, vlf, Ivr.make);
	} else {
		final endOfVF = _findEndOfULengthVF();
		return _makeElement(code, eStart, vrIndex, endOfVF, Ivr.make);
	}
}



