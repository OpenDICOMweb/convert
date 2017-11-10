// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readIvrRootDataset() {
//  _cds = _rds;
  _isEvr = false;

  log.debug('${_rb.rbb} _readIvrRootDataset: ${_rb.remaining}');
  _readDatasetDefined(_rds, _rb.rIndex, _rb.remaining, _readIvrElement);
  log.debug('${_rb.ree} $_elementCount Elements read with '
      '${_rb.remaining} bytes remaining\nDatasets: ${_pInfo.nDatasets}');
}

/// All [Element]s are read by this method.
Element _readIvrElement() {
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final tag = Tag.lookup(code);
  final vr = (tag == null) ? VR.kUN : tag.vr;

  var vrIndex = vr.index;
  if (_isSpecialVR(vrIndex) || vrIndex == -1) {
    vrIndex = VR.kUN.index;
    _rb.warn('** vrIndex changed to VR.kUN.index');
  }

  _rb.sMsg('readIvrElement', code, eStart, vrIndex);
  Element e;
  if (_isIvrDefinedLength(vrIndex)) {
    e = _readIvrDefinedLength(code, eStart, vrIndex);
  } else if (vrIndex == kVRIndexMin) {
    e = _readIvrSQ(code, eStart);
  } else if (_isMaybeUndefinedLength(vrIndex)) {
    e = _readIvrMaybeUndefinedLength(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }
  _rb.eMsg(_elementCount, e, eStart, _rb.rIndex);
  return _finishReadElement(code, eStart, e);
}

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
Element _readIvrDefinedLength(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  _rb.sMsg('_readIvrDefinedLength', code, eStart, vrIndex, 8, vfLengthField);
  _pInfo.nLongElements++;
  return __readIvrDefined(code, eStart, vrIndex, vfLengthField);
}

/// Read an IVR Element (not SQ) with a 32-bit [vfLength], but that cannot
/// have kUndefinedValue.
Element __readIvrDefined(int code, int eStart, int vrIndex, int vfLength) {
  _rb.mMsg('readIvrDefined', code, eStart, vrIndex, 8, vfLength);
  _pInfo.nDefinedElements++;
  _rb + vfLength;

  return (code == kPixelData)
      ? _makePixelData(code, eStart,  vrIndex,_rb.rIndex, false, Ivr.make)
      : _makeElement(code, eStart, vrIndex, vfLength, Ivr.make);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefinedLength(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  _pInfo.nMaybeUndefinedElements++;

  _rb.mMsg('readIvrMaybeUndefined', code, eStart, vrIndex, 8, vfLengthField);

  if (_isUNSequence(code, eStart, vrIndex)) {
    log.debug('${_rb.rmm} *** Reading Ivr UN Sequence');
    return _readIvrSQ(code, _rb.index);
  }

  return (vfLengthField == kUndefinedLength)
      ? __readIvrUndefined(code, eStart, vrIndex, vfLengthField)
      : __readIvrDefined(code, eStart, vrIndex, vfLengthField);
}

/// Read an Element (not SQ)  that has an undefined length.
Element __readIvrUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rb.sMsg('readIvrUndefined', code, eStart, vrIndex, 8, vfLengthField);
  _pInfo.nUndefinedElements++;
  if (code == kPixelData) {
    return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField, Ivr.make);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    return _makeElement(code, eStart, vrIndex, endOfVF, Ivr.make);
  }
}

Element _readIvrSQ(int code, int eStart) {
  final vfLengthField = _rb.uint32;
  _rb.sMsg('readIvrSQ', code, eStart, kSQIndex, 8, vfLengthField);

  return (vfLengthField == kUndefinedLength)
      ? _readUSQ(code, eStart, _ivrSQMaker, vfLengthField, _readIvrElement)
      : _readDSQ(code, eStart, _ivrSQMaker, vfLengthField, _readIvrElement);
}

EBytes _ivrSQMaker(ByteData bd) => new Ivr(bd);
