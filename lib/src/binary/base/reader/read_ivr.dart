// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readIvrRootDataset() {
  _cds = _rds;
  _isEvr = false;

  log.debug('${_rb.rbb} _readIvrRootDataset: ${_rb.remaining}', 1);
  _readIvrDatasetDefined(_rds, _rb.rIndex, _rb.remaining);
  log
    ..debug('${_rb.ree} $_elementCount Elements read +${_rb.remaining}', -1)
    ..debug('Element count: $_count')
    ..debug('Datasets: ${_pInfo.nDatasets}');
}

void _readIvrItem(Dataset ds, int iStart) {
  final vfLengthField = _rb.uint32;
  log.debug('${_rb.rbb} _readIvrItem $iStart:$vfLengthField', 1);

  (vfLengthField == kUndefinedLength)
      ? _readIvrDatasetUndefined(ds)
      : _readIvrDatasetDefined(ds, iStart, vfLengthField);

  log.debug('${_rb.ree} $_count Elements read', -1);
}

void _readIvrDatasetDefined(Dataset ds, int dsStart, int vfLength) {
  assert(vfLength != kUndefinedLength);
  final dsEnd = _rb.rIndex + vfLength;
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
   _readIvrElement();
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
  _rb.sMsg('readIvrElement', code, eStart, vrIndex);

  if (_isSpecialVR(vrIndex) || vrIndex == -1) {
    vrIndex = VR.kUN.index;
    _rb.warn('** vrIndex changed to VR.kUN.index');
  }

  Element e;
  if (_isIvrDefinedLength(vrIndex)) {
    e = _readIvrDefinedLength(code, eStart, vrIndex);
  } else if (vrIndex == kVRIndexMin) {
    e = _readSequence(code, eStart, _ivrSQMaker);
  } else if (_isMaybeUndefinedLength(vrIndex)) {
    e = _readIvrMaybeUndefinedLength(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }

  _elementCount++;
  _pInfo.nElements++;
  _rb.eMsg(_elementCount, e, eStart, _rb.rIndex);
  return e;
}

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
Element _readIvrDefinedLength(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  _rb.sMsg('readIvrNormal', code, eStart, vrIndex, 8, vfLengthField);
  _pInfo.nLongElements++;
  return __readIvrDefined(code, eStart, vrIndex, vfLengthField);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefinedLength(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  _rb.sMsg('readIvrMaybeUndefined', code, eStart, vrIndex, 8, vfLengthField);
  _pInfo.nMaybeUndefinedElements++;
  Element e = (vfLengthField == kUndefinedLength)
      ? _readIvrUndefined(code, eStart, vrIndex, vfLengthField)
      : __readIvrDefined(code, eStart, vrIndex, vfLengthField);
 // log.up2;
  return e;
}

/// Read an Element (not SQ)  that has an undefined length.
Element _readIvrUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rb.sMsg('readIvrUndefined', code, eStart, vrIndex, 8, vfLengthField);
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

/// Read an IVR Element (not SQ) with a 32-bit [vfLength], but that cannot
/// have kUndefinedValue.
Element __readIvrDefined(int code, int eStart, int vrIndex, int vfLength) {
  _rb.sMsg('readIvrDefined', code, eStart, vrIndex, 8, vfLength);
  _pInfo.nDefinedElements++;
  final eLength = 8 + vfLength;
  _rb + vfLength;
  if (code == kPixelData) {
    return _readPixelDataDefined(code, eStart, vrIndex, eLength, eLength);
  } else {
    final bd = _rb.buffer.asByteData(eStart, eLength);
    final eb = new Ivr(bd);
    final e = elementMaker(eb, vrIndex);
    log.up;
    return _finishReadElement(code, eStart, e);
  }
}

EBytes _ivrSQMaker(ByteData bd) => new Ivr(bd);
