// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

//TODO: redoc to reflect current state of code

Tag _tag;

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElement() {
  final eStart = _rIndex;
  final code = _rb.code;
  final vrCode = _rb.uint16;
  final vr = VR.lookupByCode(vrCode);
  if (vr == null) {
    _rb.warn('VR is Null: vrCode(${hex16(vrCode)}) ${_rb.rrr}');
    _showNext(_rIndex - 4);
  }
  final vrIndex = (_dParams.doCheckVR) ? _checkVR(code, vr.index) : vr.index;

  if (_isSequenceVR(vrIndex)) {
    return _readEvrSequence(code, eStart);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    return _readEvrMaybeUndefined(code, eStart, vrIndex);
  } else if (_isEvrLongVR(vrIndex)) {
    return _readEvrLong(code, eStart, vrIndex);
  } else if (_isEvrShortVR(vrIndex)) {
    return _readEvrShort(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }
}

Element _readEvrSequence(int code, int eStart) {
  if (_isEVR) _rb.move(2);
  return _readSequence(code, eStart, _evrSQMaker);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readEvrMaybeUndefined(int code, int eStart, int vrIndex) {
  _rb.move(2);
  final vfLengthField = _rb.uint32;
  if (vfLengthField == kUndefinedLength) {
    return _readEvrLongUndefined(code, eStart, vrIndex, vfLengthField);
  } else {
    return _readEvrLongDefined(code, eStart, vrIndex, vfLengthField);
  }
}

Element _readEvrLongUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  if (code == kPixelData) {
    return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField);
  } else {
	  final endOfElement = _findEndOfULengthVF();
	  final eLength = (endOfElement - 8) - eStart;
    final bd = _rb.buffer.asByteData(eStart, eLength);
    final eb = new EvrLong(bd);
    final e = elementMaker(eb, vrIndex);
    return _finishReadElement(code, eStart, e);
  }
}

Element _readEvrLongDefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rIndex = _rIndex + vfLengthField;
  final eLength = _rIndex - eStart;
  if (code == kPixelData) {
    return _readPixelDataDefined(code, eStart, vrIndex, vfLengthField, eLength);
  } else {
    final bd = _rb.buffer.asByteData(eStart, eLength);
    final eb = new EvrLong(bd);
    final e = elementMaker(eb, vrIndex);
    return _finishReadElement(code, eStart, e);
  }
}

/// Read an Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
/// Reads a VR of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
/// Only OB, OW, and UN can have Undefined Length.
Element _readEvrLong(int code, int eStart, int vrIndex) {
  _rb.skip(2);
  final vfLengthField = _rb.uint32;
  return _readEvrLongDefined(code, eStart, vrIndex, vfLengthField);
}

Element _readEvrShort(int code, int eStart, int vrIndex) {
  final vfLength = _rb.uint16;
  _rIndex = _rIndex + vfLength;
  final eLength = _rIndex - eStart;
  final bd = _rb.buffer.asByteData(eStart, eLength);
  final eb = new EvrShort(bd);
  final e = elementMaker(eb, vrIndex);
  return _finishReadElement(code, eStart, e);
}

EBytes _evrSQMaker(ByteData bd) => new EvrLong(bd);

//TODO: add VR.kSSUS, etc. to dictionary
/// checks that code & vrCode are compatible
int _checkVR(int code, int vrIndex, [bool warnOnUN = false]) {
  _tag = Tag.lookupByCode(code);
  var index = vrIndex;
  if (_tag == null) {
    _rb.warn('Unknown Tag Code(${dcm(code)}) ${_rb.rrr}');
  } else if (vrIndex == VR.kUN.code && _tag.vr != VR.kUN) {
    //Enhancement remove PTags with VR.kUN and add multi-values VRs
    _rb.warn('${dcm(code)} VR.kUN($vrIndex) should be ${_tag.vr} ${_rb.rrr}');
    index = _tag.vr.index;
  } else if (vrIndex != VR.kUN.index && _tag.vr.index == VR.kUN.index) {
    if (code != kPixelData && warnOnUN == true) {
      if (_tag is PDTag && _tag is! PDTagKnown) {
        log.info0('${_rb.pad} ${dcm(code)} VR.kUN: Unknown Private Data');
      } else if (_tag is PCTag && _tag is! PCTagKnown) {
        log.info0('${_rb.pad} ${dcm(code)} VR.kUN: Unknown Private Creator $_tag');
      } else {
        log.info0('${_rb.pad} ${dcm(code)} VR.kUN: $_tag');
      }
    }
  } else if (vrIndex != VR.kUN.code && vrIndex != _tag.vr.index) {
    final vr0 = VR.lookupByIndex(vrIndex);
    _rb.warn('${dcm(code)} Wrong VR $vr0($vrIndex) '
        'should be ${_tag.vr} ${_rb.rrr}');
  }
  return index;
}
