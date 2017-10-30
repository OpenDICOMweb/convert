// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

//TODO: redoc to reflect current state of code

Tag _tag;

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElement() {
  final eStart = _rIndex;
  final code = _readCode();
  final vrCode = _readUint16();
  final vr = VR.lookupByCode(vrCode);
  if (vr == null) {
    _warn('VR is Null: vrCode(${hex16(vrCode)}) $_rrr');
    _showNext(_rIndex - 4);
  }
  final vrIndex = (_dParams.doCheckVR) ? _checkVR(code, vr.index) : vr.index;

  Element e;
  if (vr.hasShortVF) {
    e = _readShortElement(code, eStart, vrIndex);
  } else {
    e = (vrIndex == VR.kSQ.index || _isSequence(code, vrIndex))
        ? _readSequence(code, eStart, _evrSQMaker)
        : _readEvrMaybeUndefined(code, eStart, vrIndex);
  }
  assert(_checkRIndex());
  return _finishReadElement(code, eStart, e);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readEvrMaybeUndefined(int code, int eStart, int vrIndex) {
	_skip(2);
	final vfLengthField = _readUint32();
  if (vfLengthField == kUndefinedLength) {
    return _readEvrLongUndefined(code, eStart, vrIndex, vfLengthField);
  } else {
    return _readEvrLongElement(code, eStart, vrIndex, vfLengthField);
  }
}

Element _readEvrLongUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
	final endOfVF = _findEndOfULengthVF();
	final eLength = endOfVF - eStart;
	_rIndex = endOfVF + 8;
	if (code == kPixelData) {
		return _readPixelDataUndefined(code, eStart,  vrIndex, vfLengthField, eLength);
	} else {
		final bd = _rootBD.buffer.asByteData(eStart, eLength);
		final eb = new EvrLong(bd);
		return elementMaker(eb, vrIndex);
	}
}
/// Read an Element (not SQ) with a 32-bit [vfLengthField], but that cannot
/// have kUndefinedValue.
/// Reads a VR of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
/// Only OB, OW, and UN can have Undefined Length.
Element _readEvrLongElement(int code, int eStart, int vrIndex, int vfLengthField) {
  _rIndex = _rIndex + vfLengthField;
  final eLength = _rIndex - eStart;
  if (code == kPixelData) {
    return _readPixelDataDefined(code, eStart,  vrIndex, vfLengthField, eLength);
  } else {
    final bd = _rootBD.buffer.asByteData(eStart, eLength);
    final eb = new EvrLong(bd);
    return elementMaker(eb, vrIndex);
  }
}

Element _readShortElement(int code, int eStart, int vrIndex) {
	final vfLength = _readUint16();
	_rIndex = _rIndex + vfLength;
	final eLength = _rIndex - eStart;
	final bd = _rootBD.buffer.asByteData(eStart, eLength);
	final eb = new EvrShort(bd);
	return elementMaker(eb, vrIndex);
}


EBytes _evrSQMaker(ByteData bd) => new EvrLong(bd);

//TODO: add VR.kSSUS, etc. to dictionary
/// checks that code & vrCode are compatible
int _checkVR(int code, int vrIndex, [bool warnOnUN = false]) {
  _tag = Tag.lookupByCode(code);
  var index = vrIndex;
  if (_tag == null) {
    _warn('Unknown Tag Code(${dcm(code)}) $_rrr');
  } else if (vrIndex == VR.kUN.code && _tag.vr != VR.kUN) {
    //Enhancement remove PTags with VR.kUN and add multi-values VRs
    _warn('${dcm(code)} VR.kUN($vrIndex) should be ${_tag.vr} $_rrr');
    index = _tag.vr.index;
  } else if (vrIndex != VR.kUN.index && _tag.vr.index == VR.kUN.index) {
    if (code != kPixelData && warnOnUN == true) {
      if (_tag is PDTag && _tag is! PDTagKnown) {
        log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Data');
      } else if (_tag is PCTag && _tag is! PCTagKnown) {
        log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Creator $_tag');
      } else {
        log.info0('$pad ${dcm(code)} VR.kUN: $_tag');
      }
    }
  } else if (vrIndex != VR.kUN.code && vrIndex != _tag.vr.index) {
    final vr0 = VR.lookupByIndex(vrIndex);
    _warn('${dcm(code)} Wrong VR $vr0($vrIndex) '
        'should be ${_tag.vr} $_rrr');
  }
  return index;
}



