// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

//TODO: redoc to reflect current state of code

Tag _tag;
int _vrCode;

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElement() {
  final eStart = _rIndex;
  final code = _readCode();
  final vrCode = _readUint16();
  final vr = VR.lookup(vrCode);
  if (vr == null) {
    _warn('VR is Null: vrCode(${hex16(vrCode)}) $_rrr');
    _showNext(_rIndex - 4);
  }
  final vrIndex = (_decode.doCheckVR) ? _checkVR(code, vrCode) : vr.index;

  Element e;
  if (vr.hasShortVF) {
    e = _readShortElement(code, eStart, vrIndex);
  } else {
    e = (vrIndex == VR.kSQ.index || _isSequence(code, vrIndex))
        ? _readEvrSequence(code, eStart)
        : _readLongEvrElement(code, eStart, vrIndex);
  }
  assert(_checkRIndex());
  return _finishReadElement(code, eStart, e);
}

Element _readShortElement(int code, int eStart, int vrIndex) {
  _rIndex = _rIndex + _readUint16();
  final eLength = _rIndex - eStart;
  final bd = _rootBD.buffer.asByteData(eStart, eLength);
  final eb = new EvrShort(bd);
  return makeElement(code, eb, vrIndex);
}

/// Reads a VR of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
/// Only OB, OW, and UN can have Undefined Length.
Element _readLongEvrElement(int code, int eStart, int vrIndex) {
  _skip(2);
  return _readLongElement(code, eStart, vrIndex);
}

SQ _readEvrSequence(int code, int eStart) {
  _skip(2);
  return _readSequence(code, eStart, _evrSQMaker);
}

EBytes _evrSQMaker(ByteData bd) => new EvrLong(bd);

//TODO: add VR.kSSUS, etc. to dictionary
/// checks that code & vrCode are compatible
int _checkVR(int code, int vrCode, [bool warnOnUN = false]) {
  _tag = Tag.lookupByCode(code);
  if (_tag == null) {
    _warn('Unknown Tag Code(${dcm(code)}) $_rrr');
  } else if (vrCode == VR.kUN.code && _tag.vr != VR.kUN) {
    //Enhancement remove PTags with VR.kUN and add multi-values VRs
    _warn('${dcm(code)} VR.kUN($vrCode) should be ${_tag.vr} $_rrr');
    _vrCode = _tag.vr.code;
  } else if (vrCode != VR.kUN.code && _tag.vr.code == VR.kUN.code) {
    if (code != kPixelData && warnOnUN == true) {
      if (_tag is PDTag && _tag is! PDTagKnown) {
        log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Data');
      } else if (_tag is PCTag && _tag is! PCTagKnown) {
        log.info0('$pad ${dcm(code)} VR.kUN: Unknown Private Creator $_tag');
      } else {
        log.info0('$pad ${dcm(code)} VR.kUN: $_tag');
      }
    }
  } else if (vrCode != VR.kUN.code && vrCode != _tag.vr.code) {
    final vr0 = VR.lookup(vrCode);
    _warn('${dcm(code)} Wrong VR $vr0($vrCode) '
        'should be ${_tag.vr} $_rrr');
  }
  return _vrCode;
}
