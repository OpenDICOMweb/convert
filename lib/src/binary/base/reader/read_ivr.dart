// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

/// All [Element]s are read by this method.
Element _readIvrElement() {
  final eStart = _rIndex;
  final code = _readCode();
  Tag tag;
  VR vr;
  int vrIndex;
  if (Tag.isPublicCode(code)) {
    tag = Tag.lookup(code, VR.kUN);
    vr = (tag == null) ? VR.kUN : tag.vr;
    vrIndex = vr.index;
  } else {
    tag = Tag.lookup(code, VR.kUN);
    vr = (tag == null) ? VR.kUN : tag.vr;
    vrIndex = vr.index;
  }
  final e = (vrIndex == VR.kSQ.index || _isSequence(code, vrIndex))
      ? _readSequence(code, eStart, _ivrSQMaker)
      : _readIvrMaybeUndefined(code, eStart, vrIndex);
  assert(_checkRIndex());

  return _finishReadElement(code, eStart, e);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefined(int code, int eStart, int vrIndex) {
  final vfLengthField = _readUint32();
  if (vfLengthField == kUndefinedLength) {
    return _readIvrUndefined(code, eStart, vrIndex, vfLengthField);
  } else {
    return _readIvrDefined(code, eStart, vrIndex, vfLengthField);
  }
}

/// Read an Element (not SQ)  that has an undefined length.
Element _readIvrUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  final endOfVF = _findEndOfULengthVF();
  final eLength = endOfVF - eStart;
  if (code == kPixelData) {
	  return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField, eLength);
  } else {
  	_rIndex = endOfVF + 8;
	  final bd = _rootBD.buffer.asByteData(eStart, eLength);
	  final eb = new EvrLong(bd);
	  return elementMaker(eb, vrIndex);
  }
}

/// Read an IVR Element (not SQ) with a 32-bit [vfLengthField], but that cannot
/// have kUndefinedValue.
Element _readIvrDefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rIndex = _rIndex + vfLengthField;
  final eLength = _rIndex - eStart;
  if (code == kPixelData) {
	  return _makePixelData(eStart, eLength, vrIndex);
  } else {
	  final bd = _rootBD.buffer.asByteData(eStart, eLength);
	  final eb = new Ivr(bd);
	  return elementMaker(eb, vrIndex);
  }
}

EBytes _ivrSQMaker(ByteData bd) => new Ivr(bd);
