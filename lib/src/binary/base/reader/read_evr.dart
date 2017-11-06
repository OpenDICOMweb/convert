// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readEvrRootDataset() {
  _parentDS = _rds;
  _cds = _rds;
  _isEvr = true;

  log.debug('${_rb.rbb} _readEvrRootDataset ${_rb.rIndex} : ${_rb.remaining}', 1);
  __readEvrDataset(_rds, _rb.rIndex, _rb.remaining);
  log
    ..debug('${_rb.ree} $_count Elements read +${_rb.remaining}', -1)
    ..debug('Element count: $_count')
    ..debug('Datasets: ${_pInfo.nDatasets}');
}

void _readEvrItem(Dataset ds, int iStart) {
  final vfLengthField = _rb.uint32;
  log.debug('${_rb.rbb} _readEvrItem $iStart $vfLengthField', 1);
  __readEvrDataset(ds, iStart, vfLengthField);
  log.debug('${_rb.ree} _readEvrItem $_count Element read', -1);
}

void __readEvrDataset(Dataset ds, int dsStart, int vfLengthField) =>
    (vfLengthField == kUndefinedLength)
        ? _readEvrDatasetUndefined(ds)
        : _readEvrDatasetDefined(ds, dsStart, vfLengthField);

void _readEvrDatasetDefined(Dataset ds, int dsStart, int vfLengthField) {
	final dsEnd = _rb.rIndex + vfLengthField;
  log.debug2('${_rb.rbb} _readEvrDatasetDefined $dsStart, $vfLengthField, $deletedElementError(key)', 1);

  while (_rb.rIndex < dsEnd) {
    _readEvrElement();
    // Urgent Jim: remove count everywhere
    _count++;
  }

  log.debug2('${_rb.ree} $_count Elements read', -1);
  _pInfo.nDefinedDatasets++;
}

void _readEvrDatasetUndefined(Dataset ds) {
  log.debug2('${_rb.rbb} _readEvrDatasetUndefined', 1);

  while (!_rb.isItemDelimiter()) {
    ds.add(_readEvrElement());
    _count++;
  }

  log.debug2('${_rb.ree} $_count Elements read', -1);
  _pInfo.nUndefinedDatasets++;
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

  log.debug2('${_rb.rbb} _readEvrElement${dcm(code)} $vr $eStart +${_rb.remaining}', 1);
  var vrIndex = (_dParams.doCheckVR) ? _checkVR(code, vr.index) : vr.index;

  if (_isSpecialVR(vrIndex)) {
    vrIndex = VR.kUN.index;
    _rb.warn('** vrIndex changed to VR.kUN.index');
  }

  // TODO: figure out the fastest path through
  // TODO: i.e. which elements occure most often?
  Element e;
  if (_isEvrShortVR(vrIndex)) {
    e = _readEvrShort(code, eStart, vrIndex);
  } else if (_isSequenceVR(vrIndex)) {
    e = _readEvrSQ(code, eStart);
  } else if (_isEvrLongVR(vrIndex)) {
    e = _readEvrLong(code, eStart, vrIndex);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    e = _readEvrMaybeUndefined(code, eStart, vrIndex);
  } else {
    return invalidVRIndexError(vrIndex);
  }

  _elementCount++;
  _pInfo.nElements++;
  log.debug2('${_rb.ree} $_elementCount $e +${_rb.remaining}', -1);
  return e;
}

/// Read a Short EVR Element, i.e. one with a 16-bit
/// Value Field Length field. These Elements may not have
/// a kUndefinedLength value.
Element _readEvrShort(int code, int eStart, int vrIndex) {
  final vfLength = _rb.uint16;
  _rb.sMsg('_readEvrShort', code, eStart, vrIndex: vrIndex, vfLength: vfLength);
  final endOfVF = _rb + vfLength;
  final eLength = endOfVF - eStart;
  final bd = _rb.buffer.asByteData(eStart, eLength);
  final eb = new EvrShort(bd);
  final e = elementMaker(eb, vrIndex);
  _pInfo.nShortElements++;
  return _finishReadElement(code, eStart, e);
}

/// Read and EVR Sequence.
Element _readEvrSQ(int code, int eStart) {
  _rb + 2;
  _rb.sMsg('_readEvrSQ', code, eStart);
  final e = _readSequence(code, eStart, _evrSQMaker);
  return _finishReadElement(code, eStart, e);
}

/// Read a Long EVR Element (not SQ) with a 32-bit vfLengthField,
/// but that cannot have the value kUndefinedValue.
///
/// Reads one of OB, OD, OF, OL, OW, UC, UN, UR, or UT.
Element _readEvrLong(int code, int eStart, int vrIndex) {
  _rb + 2;
  _rb.sMsg('_readEvrLong', code, eStart);

  final vfLengthField = _rb.uint32;
  final e = __readEvrLongDefined(code, eStart, vrIndex, vfLengthField);

  _pInfo.nLongElements++;
  return _finishReadElement(code, eStart, e);
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

  _rb.sMsg('_readEvrMaybeUndefined', code, eStart,
      vrIndex: vrIndex, vfLength: vfLengthField);

 // final v = _rb.getUint32(_rb.rIndex);

  if (vrIndex == kUNIndex && (_rb.isItemDelimiter() || _rb.isSequenceDelimiter())) {
    // A UN Sequence
    log.debug('${_rb.rmm} Reading UN Sequence');
    _rb.index = eStart;
    return _readSequence(code, eStart, _evrSQMaker);
  }

  final e = (vfLengthField == kUndefinedLength)
      ? __readEvrUndefined(code, eStart, vrIndex, vfLengthField)
      : __readEvrLongDefined(code, eStart, vrIndex, vfLengthField);

  _pInfo.nMaybeUndefinedElements++;
  return _finishReadElement(code, eStart, e);
}

// Finish reading an EVR Long Undefined Length Element
Element __readEvrUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _pInfo.nUndefinedElements++;
  if (code == kPixelData) {
    return _readPixelDataUndefined(code, eStart, vrIndex, vfLengthField);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    return __makeEvrLongElement(code, eStart, endOfVF - eStart, vrIndex);
  }
}

Element __makeEvrLongElement(int code, int eStart, int eLength, int vrIndex) {
  final bd = _rb.buffer.asByteData(eStart, eLength);
  final eb = new EvrLong(bd);
  final e = elementMaker(eb, vrIndex);
  return e;
}

// Finish reading an EVR Long Defined Length Element
Element __readEvrLongDefined(int code, int eStart, int vrIndex, int vfLengthField) {
  _rb.mMsg('__readEvrLongDefined', code, eStart,
      vrIndex: vrIndex, vfLength: vfLengthField);
  final end = _rb + vfLengthField;
  final eLength = end - eStart;
  _pInfo.nDefinedElements++;

  if (code == kPixelData) {
    return _readPixelDataDefined(code, eStart, vrIndex, vfLengthField, eLength);
  } else {
    //final eLength = eStart + 12 + vfLengthField;
    return __makeEvrLongElement(code, eStart, eLength, vrIndex);
  }
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
