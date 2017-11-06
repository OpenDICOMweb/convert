// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readIvrRootDataset() {
  _parentDS = _rds;
  _currentDS = _rds;
  _isEvr = false;

  log.debug('${_rb.rbb} _readIvrRootDataset: ${_rb.remaining}', 1);
  __readIvrDataset(_rds, _rb.rIndex, _rb.remaining);
  log
    ..debug('${_rb.ree} $_count Elements read +${_rb.remaining}', -1)
    ..debug('Element count: $_count')
    ..debug('Datasets: ${_pInfo.nDatasets}');
}

void _readIvrItem(Dataset ds, int iStart) {
	final vfLengthField = _rb.uint32;
	log.debug('${_rb.rbb} _readIvrItem $iStart:$vfLengthField', 1);
	__readIvrDataset(ds, iStart, vfLengthField);
	log.debug('${_rb.ree} $_count Elements read', -1);
}

void __readIvrDataset(Dataset ds, int dsStart, int vfLengthField) =>
    (vfLengthField == kUndefinedLength)
        ? _readIvrDatasetUndefined(ds)
        : _readIvrDatasetDefined(ds, dsStart + vfLengthField);

void _readIvrDatasetDefined(Dataset ds, int dsEnd) {
	log.debug2('${_rb.rbb} _readEvrDatasetDefined', 1);

  while (_rb.rIndex < dsEnd) {
    _readIvrElement();
    _count++;
  }

  log.debug2('${_rb.ree} $_count Elements read', -1);
  _pInfo.nDefinedDatasets++;
}

void _readIvrDatasetUndefined(Dataset ds) {
  log.debug2('${_rb.rbb} _readIvrDatasetUndefined', 1);

  while (!_rb.isItemDelimiter()) {
    ds.add(_readIvrElement());
    _count++;
  }

  log.debug2('${_rb.ree} $_count Elements read', -1);
  _pInfo.nUndefinedDatasets++;
}

/// All [Element]s are read by this method.
Element _readIvrElement() {
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final tag = Tag.lookup(code);
//  _tag = tag;
  final vr = (tag == null) ? VR.kUN : tag.vr;
  var vrIndex = vr.index;
  _rb.sMsg('readIvrElement' , code, eStart);

  if (_isSpecialVR(vrIndex)) {
    vrIndex = VR.kUN.index;
    _rb.warn('** vrIndex changed to VR.kUN.index');
  }

  Element e;
  if (_isIvrVR(vrIndex)) {
    e = _readIvrNormal(code, eStart, vrIndex);
  } else if (vrIndex == kVRIndexMin) {
    e = _readSequence(code, eStart, _ivrSQMaker);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    e = _readIvrMaybeUndefined(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }

  _elementCount++;
  _pInfo.nElements++;
  _rb.eMsg(e);
  return e;
}

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
Element _readIvrNormal(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  _pInfo.nLongElements++;
  return _readIvrDefined(code, eStart, vrIndex, vfLengthField);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefined(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  _pInfo.nMaybeUndefinedElements++;
  return (vfLengthField == kUndefinedLength)
      ? _readIvrUndefined(code, eStart, vrIndex, vfLengthField)
      : _readIvrDefined(code, eStart, vrIndex, vfLengthField);
}

/// Read an Element (not SQ)  that has an undefined length.
Element _readIvrUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
	_pInfo.nUndefinedElements++;
  if (code == kPixelData) {
    return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    final bd = _rb.buffer.asByteData(eStart, endOfVF - eStart);
    final eb = new Ivr(bd);
    final e = elementMaker(eb, vrIndex);
    return _finishReadElement(code, eStart, e);
  }
}

/// Read an IVR Element (not SQ) with a 32-bit [vfLengthField], but that cannot
/// have kUndefinedValue.
Element _readIvrDefined(int code, int eStart, int vrIndex, int vfLengthField) {
	_pInfo.nDefinedElements++;
  final end = _rb + vfLengthField;
  final eLength = end - eStart;
  if (code == kPixelData) {
    final e = _makePixelData(eStart, eLength, vrIndex);
    return _finishReadElement(code, eStart, e);
  } else {
    final bd = _rb.buffer.asByteData(eStart, eLength);
    final eb = new Ivr(bd);
    final e = elementMaker(eb, vrIndex);
    return _finishReadElement(code, eStart, e);
  }
}

EBytes _ivrSQMaker(ByteData bd) => new Ivr(bd);
