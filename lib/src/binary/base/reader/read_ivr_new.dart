// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

const int kIvrUndefinedStart = 1; // OB, OW, UN
const int kIvrUndefinedEnd = 3;
const int kIvrLongStart = 4; // UC, UR, UT
const int kIvrLongEnd = 6;
const int kIvrShortStart = 7; // UC, UR, UT
const int kIvrShortEnd = 32;

/// All [Element]s are read by this method.
Element _readIvrElementNVR() {
  final eStart = _rIndex;
  final code = _readCode();
  // No VR get Tag
  final tag = Tag.lookup(code);
  final vr = (tag == null) ? VR.kUN : tag.vr;
  final vrIndex = vr.index;

  if (vrIndex == 0) {
    return _readSequence(code, eStart, _ivrSQMakerNVR);
  } else if (vrIndex >= kIvrUndefinedStart && vrIndex <= kIvrUndefinedEnd) {
    return _readIvrMaybeUndefinedNVR(code, eStart, vrIndex);
  } else if (vrIndex >= kIvrLongStart && vrIndex <= kIvrLongEnd) {
    return _readIvrNVR(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefinedNVR(int code, int eStart, int vrIndex) {
  final vfLengthField = _readUint32();
  if (vfLengthField == kUndefinedLength) {
    return _readIvrUndefinedNVR(code, eStart, vrIndex, vfLengthField);
  } else {
    return _readIvrDefinedNVR(code, eStart, vrIndex, vfLengthField);
  }
}

/// Read an Element (not SQ)  that has an undefined length.
Element _readIvrUndefinedNVR(int code, int eStart, int vrIndex, int vfLengthField) {
  final endOfVF = _findEndOfULengthVF();
  final eLength = endOfVF - eStart;
  _rIndex = endOfVF + 8;

  final bd = _rootBD.buffer.asByteData(eStart, eLength);
  final eb = new Ivr(bd);
  return elementMaker(eb, vrIndex);
}

/// Read an IVR Element (not SQ) with a 32-bit [vfLengthField], but that cannot
/// have kUndefinedValue.
Element _readIvrDefinedNVR(int code, int eStart, int vrIndex, int vfLengthField) {
  _rIndex = _rIndex + vfLengthField;
  final eLength = _rIndex - eStart;
  if (code == kPixelData)
    return _readPixelDataDefined(code, eStart, vrIndex, vfLengthField, eLength);
  final bd = _rootBD.buffer.asByteData(eStart, eLength);
  final eb = new Ivr(bd);
  return elementMaker(eb, vrIndex);
}

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
Element _readIvrNVR(int code, int eStart, int vrIndex) {
  final vfLengthField = _readUint32();
  return _readIvrDefinedNVR(code, eStart, vrIndex, vfLengthField);
}

EBytes _ivrSQMakerNVR(ByteData bd) => new Ivr(bd);
