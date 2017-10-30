// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

//TODO: redoc to reflect current state of code

Tag _tagNVR;

const int kEvrUndefinedStart = 1; // OB, OW, UN
const int kEvrUndefinedEnd = 3;
const int kEvrLongStart = 4; // UC, UR, UT
const int kEvrLongEnd = 6;
const int kEvrShortStart = 7; // UC, UR, UT
const int kEvrShortEnd = 32;

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElementNVR() {
  final eStart = _rIndex;
  final code = _readCode();
  final vrCode = _readUint16();
  final vr = VR.lookupByCode(vrCode);
  if (vr == null) {
    _warn('VR is Null: vrCode(${hex16(vrCode)}) $_rrr');
    _showNext(_rIndex - 4);
  }
  final vrIndex = (_dParams.doCheckVR) ? _checkVRNVR(code, vr.index) : vr.index;

  if (vrIndex == 0) {
    return _readSequence(code, eStart, _evrSQMakerNVR);
  } else if (vrIndex >= VR.kMaybeUndefinedMin && vrIndex <= VR.kMaybeUndefinedMax) {
    return _readEvrMaybeUndefinedNVR(code, eStart, vrIndex);
  } else if (vrIndex >= VR.kEvrLongMin && vrIndex <= VR.kEvrLongMax) {
    return _readEvrLongNVR(code, eStart, vrIndex);
  } else if (vrIndex >= VR.kEvrShortMin && vrIndex <= VR.kEvrShortMax) {
    return _readEvrShortNVR(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readEvrMaybeUndefinedNVR(int code, int eStart, int vrIndex) {
  final vfLengthField = _readUint32();
  if (vfLengthField == kUndefinedLength) {
    return _readEvrLongUndefinedNVR(code, eStart, vrIndex, vfLengthField);
  } else {
    return _readEvrLongDefinedNVR(code, eStart, vrIndex, vfLengthField);
  }
}

Element _readEvrLongUndefinedNVR(int code, int eStart, int vrIndex, int vfLengthField) {
  final endOfVF = _findEndOfULengthVF();
  final eLength = endOfVF - eStart;
  _rIndex = endOfVF + 8;
  if (code == kPixelData) {
    return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField, eLength);
  } else {
    final bd = _rootBD.buffer.asByteData(eStart, eLength);
    final eb = new EvrLong(bd);
    return elementMaker(eb, vrIndex);
  }
}

Element _readEvrLongDefinedNVR(int code, int eStart, int vrIndex, int vfLengthField) {
	_rIndex = _rIndex + vfLengthField;
	final eLength = _rIndex - eStart;
	if (code == kPixelData) {
		return _readPixelDataDefined(code, eStart, vrIndex, vfLengthField, eLength);
	} else {
		final bd = _rootBD.buffer.asByteData(eStart, eLength);
		final eb = new EvrLong(bd);
		return elementMaker(eb, vrIndex);
	}
}
/// Read an Element (not SQ) with a 32-bit vfLengthField, but that cannot
/// have kUndefinedValue.
/// Reads a VR of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
/// Only OB, OW, and UN can have Undefined Length.
Element _readEvrLongNVR(int code, int eStart, int vrIndex) {
  _skip(2);
  final vfLengthField = _readUint32();
  return _readEvrLongDefinedNVR(code, eStart, vrIndex, vfLengthField);
}

Element _readEvrShortNVR(int code, int eStart, int vrIndex) {
  final vfLength = _readUint16();
  _rIndex = _rIndex + vfLength;
  final eLength = _rIndex - eStart;
  final bd = _rootBD.buffer.asByteData(eStart, eLength);
  final eb = new EvrShort(bd);
  return elementMaker(eb, vrIndex);
}

EBytes _evrSQMakerNVR(ByteData bd) => new EvrLong(bd);

//TODO: add VR.kSSUS, etc. to dictionary
/// checks that code & vrCode are compatible
int _checkVRNVR(int code, int vrIndex, [bool warnOnUN = false]) {
  _tagNVR = Tag.lookupByCode(code);
  var index = vrIndex;
  if (_tagNVR == null) {
    _warn('Unknown Tag Code(${dcm(code)}) $_rrr');
  } else if (vrIndex == VR.kUN.code && _tagNVR.vr != VR.kUN) {
    //Enhancement remove PTags with VR.kUN and add multi-values VRs
    _warn('${dcm(code)} VR.kUN($vrIndex) should be ${_tagNVR.vr} $_rrr');
    index = _tagNVR.vr.index;
  } else if (vrIndex != VR.kUN.index && _tagNVR.vr.index == VR.kUN.index) {
    if (code != kPixelData && warnOnUN == true) {
      if (_tagNVR is PDTag && _tagNVR is! PDTagKnown) {
        log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Data');
      } else if (_tagNVR is PCTag && _tagNVR is! PCTagKnown) {
        log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Creator $_tagNVR');
      } else {
        log.info0('$pad ${dcm(code)} VR.kUN: $_tagNVR');
      }
    }
  } else if (vrIndex != VR.kUN.code && vrIndex != _tagNVR.vr.index) {
    final vr0 = VR.lookupByIndex(vrIndex);
    _warn('${dcm(code)} Wrong VR $vr0($vrIndex) '
        'should be ${_tagNVR.vr} $_rrr');
  }
  return index;
}

