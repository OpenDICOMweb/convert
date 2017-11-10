// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readEvrRootDataset() {
  // _cds = _rds;
  _isEvr = true;

  log.debug('readEvrRootDataset');
  _readDatasetDefined(_rds, _rb.rIndex, _rb.remaining, _readEvrElement);
  log.debug('${_rb.ree} $_elementCount Elements read with '
      '${_rb.remaining} bytes remaining\nDatasets: ${_pInfo.nDatasets}');
}

/// For EVR Datasets, all Elements are read by this method.
Element _readEvrElement() {
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final vrCode = _rb.uint16;
  final vr = VR.lookupByCode(vrCode);
  if (vr == null) {
    _rb.warn('VR is Null: vrCode(${hex16(vrCode)}) '
        '${dcm(code)} start: $eStart ${_rb.rrr}');
    _showNext(_rb.rIndex - 4);
  }

  var vrIndex = vr.index;
  if (_isSpecialVR(vrIndex)) {
    vrIndex = VR.kUN.index;
    _rb.warn('** vrIndex changed to VR.kUN.index');
  }
  vrIndex = (_dParams.doCheckVR) ? _checkVR(code, vr.index) : vr.index;

  _rb.sMsg('readEvrElement', code, eStart, vrIndex);
  // TODO: figure out the fastest path through
  // TODO: i.e. which elements occure most often?
  Element e;
  if (_isEvrShortVR(vrIndex)) {
    e = _readEvrShort(code, eStart, vrIndex);
  } else if (_isSequenceVR(vrIndex)) {
    e = _readEvrSQ(code, eStart);
  } else if (_isEvrLongVR(vrIndex)) {
    e = _readEvrLong(code, eStart, vrIndex);
  } else if (_isMaybeUndefinedLength(vrIndex)) {
    e = _readEvrMaybeUndefined(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }
  _rb.eMsg(_elementCount, e, eStart, _rb.rIndex);
  return _finishReadElement(code, eStart, e);
}

/// Read a Short EVR Element, i.e. one with a 16-bit
/// Value Field Length field. These Elements may not have
/// a kUndefinedLength value.
Element _readEvrShort(int code, int eStart, int vrIndex) {
  final vfLength = _rb.uint16;
  _rb + vfLength;
  _rb.sMsg('readEvrShort', code, eStart, vrIndex, 8, _rb.rIndex);
  _pInfo.nShortElements++;
  return _makeElement(code, eStart, vrIndex, vfLength, EvrShort.make);
}

/// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
/// but that cannot have the value kUndefinedValue.
///
/// Reads one of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
Element _readEvrLong(int code, int eStart, int vrIndex) {
  _rb + 2;
  final vfLengthField = _rb.uint32;
  _rb.sMsg('readEvrLong', code, eStart, vrIndex, 12, vfLengthField);
  _pInfo.nLongElements++;
  return __readEvrLongDefined(code, eStart, vrIndex, vfLengthField);
}

// Finish reading an EVR Long Defined Length Element
Element __readEvrLongDefined(int code, int eStart, int vrIndex, int vfLength) {
  _rb.sMsg('readEvrLongDefined', code, eStart, vrIndex, 12, vfLength);
  _pInfo.nDefinedElements++;
  _rb + vfLength;

  return (code == kPixelData)
      ? _makePixelData(code, eStart, vrIndex, _rb.rIndex, false, EvrLong.make)
      : _makeElement(code, eStart, vrIndex, vfLength, EvrLong.make);
}

/// Read a long EVR Element (not SQ) with a 32-bit vfLengthField,
/// that might have a value of kUndefinedValue.
///
/// Reads one of OB, OW, and UN.
//  If the Element if UN then it maybe a Sequence.  If it is it will
//  start with either a kItem delimiter or if it is an empty undefined
//  Sequence it will start with a kSequenceDelimiter.
Element _readEvrMaybeUndefined(int code, int eStart, int vrIndex) {
  _rb + 2;
  final vfLengthField = _rb.uint32;
  _pInfo.nMaybeUndefinedElements++;

  _rb.mMsg('readEvrMaybeUndefined', code, eStart, vrIndex, 8, vfLengthField);

  if (vrIndex == kUNIndex) {
    log.debug('${_rb.rmm} *** Reading Evr UN Sequence');
    final delimiter = _rb.getUint32(_rb.rIndex);
    if (delimiter == kSequenceDelimitationItem32BitLE) {
      _rb.readAndCheckDelimiterLength();
      return _makeSequence(code, eStart, EvrLong.make, emptyItemList);
    } else if (delimiter == kItem) {
      _rb.readAndCheckDelimiterLength();
      return _readUSQ(code, eStart, EvrLong.make, vfLengthField, _readEvrElement);
    }
  }

  return (vfLengthField == kUndefinedLength)
      ? __readEvrUndefined(code, eStart, vrIndex, vfLengthField)
      : __readEvrLongDefined(code, eStart, vrIndex, vfLengthField);
}

// Finish reading an EVR Long Undefined Length Element
Element __readEvrUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rb.sMsg('readEvrLongDefined', code, eStart, vrIndex, 20, vfLengthField);
  _pInfo.nUndefinedElements++;
  if (code == kPixelData) {
    return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField, EvrLong.make);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    return _makeElement(code, eStart, vrIndex, endOfVF, EvrLong.make);
  }
}

/// Read and EVR Sequence.
Element _readEvrSQ(int code, int eStart) {
  _rb + 2;
  final vfLengthField = _rb.uint32;
  _rb.sMsg('readEvrSQ', code, eStart, kSQIndex, 12, vfLengthField);

  return (vfLengthField == kUndefinedLength)
      ? _readUSQ(code, eStart, _evrSQMaker, vfLengthField, _readEvrElement)
      : _readDSQ(code, eStart, _evrSQMaker, vfLengthField, _readEvrElement);
}

EBytes _evrSQMaker(ByteData bd) => new EvrLong(bd);

//TODO: add VR.kSSUS, etc. to dictionary
/// checks that code & vrCode are compatible
int _checkVR(int code, int vrIndex, [bool warnOnUN = false]) {
  tag = Tag.lookupByCode(code);
  final tagVR = tag.vr;
  final tagVRIndex = tagVR.index;
  if (tag == null) {
    _rb.warn('Unknown Tag Code(${dcm(code)}) ${_rb.rrr}');
    return vrIndex;
  } else if (vrIndex == tagVRIndex) {
    return vrIndex;
  } else if (vrIndex == VR.kUN.code && tagVR != VR.kUN) {
    //Enhancement remove PTags with VR.kUN and add multi-values VRs
    _rb.warn('${dcm(code)} VR.kUN($vrIndex) changing to ${tag.vr} ${_rb.rrr}');
    return tagVRIndex;
  } else if (tagVR is! VRIntSpecial) {
    final vr = VR.lookupByIndex(vrIndex);
    log.info('VR $vr is valid for $tag');
    //Urgent: create a switch that allow this to be changed to correct vr.
    return vrIndex;
  } else if (tagVR is VRIntSpecial) {
    if (tagVR.isValidVRIndex(vrIndex)) return vrIndex;
  } else if (vrIndex != VR.kUN.code) {
    if (code != kPixelData && warnOnUN == true) {
      if (tag is PDTag && tag is! PDTagKnown) {
        log.info0('${_rb.pad} ${dcm(code)} VR.kUN: Unknown Private Data');
      } else if (tag is PCTag && tag is! PCTagKnown) {
        log.info0('${_rb.pad} ${dcm(code)} VR.kUN: Unknown Private Creator $tag');
      } else {
        log.info0('${_rb.pad} ${dcm(code)} VR.kUN: $tag');
      }
    }
  }
  log.debug2('VRin  vrIndex');
  return vrIndex;
}
