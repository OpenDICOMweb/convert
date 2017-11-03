// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

/// All [Element]s are read by this method.
Element _readIvrElement() {
  final eStart = _rIndex;
  final code = _rb.code;
  // No VR get Tag
  final tag = Tag.lookup(code);
  final vr = (tag == null) ? VR.kUN : tag.vr;
  var vrIndex = vr.index;
  log.debug1('${_rb.rbb} $eStart: ${dcm(code)} ${vr.info}');
 // log.debug2('  $tag');

  if (_isSpecialVR(vrIndex)) {
  	vrIndex = VR.kUN.index;
  	log.debug('** vrIndex changed to VR.kUN.index');
  }
  if (vrIndex == kVRIndexMin) {
    return _readSequence(code, eStart, _ivrSQMaker);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    return _readIvrMaybeUndefined(code, eStart, vrIndex);
  } else if (_isIvrVR(vrIndex)) {
    return _readIvr(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefined(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
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
  _rIndex = endOfVF + 8;
  final bd = _rb.buffer.asByteData(eStart, eLength);
  final eb = new Ivr(bd);
  final e = elementMaker(eb, vrIndex);
  return _finishReadElement(code, eStart, e);
}

/// Read an IVR Element (not SQ) with a 32-bit [vfLengthField], but that cannot
/// have kUndefinedValue.
Element _readIvrDefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rIndex = _rIndex + vfLengthField;
  final eLength = _rIndex - eStart;
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

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
Element _readIvr(int code, int eStart, int vrIndex) {
  final vfLengthField = _rb.uint32;
  return _readIvrDefined(code, eStart, vrIndex, vfLengthField);
}

EBytes _ivrSQMaker(ByteData bd) => new Ivr(bd);
