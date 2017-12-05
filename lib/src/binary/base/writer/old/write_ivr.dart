// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeIvrRootDataset(RootDataset rds, EncodingParameters eParams) {
  _rds = rds;
  _cds = rds;
  _isEvr = false;

  log.debug('${_wb.wbb} _writeIvrRootDataset $rds :${_wb.remaining}', 1);

  // Make FMI a separate part of rds.
  for (var e in rds.elements) {
    if (e.code < 0x00030000) {
      _writeEvrElement(e);
    } else {
      _writeIvrElement(e);
    }
  }
  log.debug('${_wb.wee} _writeIvrRootDataset  :${_wb.remaining}', -1);
}

void _writeIvrElement(Element e) {
	_elementCount++;
  log.debug('${_wb.wbb} _writeIvrElement $e :${_wb.remaining}', 1);
  final eStart = _wb.wIndex;
  var vrIndex = e.vrIndex;

  if (_isSpecialVR(vrIndex)) {
    vrIndex = VR.kUN.index;
    _wb.warn('** vrIndex changed to VR.kUN.index');
  }

  if (_isIvrDefinedLengthVR(vrIndex)) {
    _writeSimpleIvr(e);
  } else if (_isSequenceVR(vrIndex)) {
    _writeIvrSQ(e);
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
    _writeIvrMaybeUndefined(e);
  } else if (_isSpecialVR(vrIndex)) {
    _writeIvrMaybeUndefined(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }
//  print('Level: ${log.indenter.level}');
  log.debug('${_wb.wee} _writeIvrElement ${e.dcm} ${e.keyword}');
  _pInfo.nElements++;
  _doEndOfElementStats(eStart, _wb.wIndex, e);
}

void _writeSimpleIvr(Element e) {
  log.debug('${_wb.wbb} writeSimpleIvr $e :${_wb.remaining}', 1);
  __reallyWriteIvrDefinedLength(e);
}

void _writeIvrMaybeUndefined(Element e) {
	log.debug('${_wb.wbb} writeIvrMaybeUndefined $e :${_wb.remaining}', 1);
  _pInfo.nMaybeUndefinedElements++;
  return (e.hadULength && !_eParams.doConvertUndefinedLengths)
      ? __reallyWriteIvrUndefinedLength(e)
      : __reallyWriteIvrDefinedLength(e);
}

void _writeIvrSQ(SQ e) {
  _pInfo.nSequences++;
  if (e.isPrivate) _pInfo.nPrivateSequences++;
  return (e.hadULength && !_eParams.doConvertUndefinedLengths)
      ? _writeIvrSQUndefinedLength(e)
      : _writeIvrSQDefinedLength(e);
}

void _writeIvrSQDefinedLength(SQ e) {
  log.debug('${_wb.wbb} _writeIvrSQDefined $e :${_wb.remaining}', 1);
  _pInfo.nDefinedLengthSequences++;
  __reallyWriteIvrDefinedLength(e);
}

void _writeIvrSQUndefinedLength(SQ e) {
  log.debug('${_wb.wbb} _writeIvrSQUndefined $e :${_wb.remaining}', 1);
  _pInfo.nUndefinedLengthSequences++;
  __reallyWriteIvrUndefinedLength(e);
}

void __reallyWriteIvrDefinedLength(Element e) {
  assert(e.vfLengthField != kUndefinedLength);
  if (e.code == kPixelData) {
    __updatePInfoPixelData(e);
  } else {
    log.debug('${_wb.wmm} _writeSimpleIvr $e :${_wb.remaining}', 1);
  }
  _wb
    ..code(e.code)
    ..uint32(e.vfLength);
  __writeValueField(e);
  _pInfo.nLongElements++;
}

void __reallyWriteIvrUndefinedLength(Element e) {
	assert(e.vfLengthField == kUndefinedLength);
	if (e.code == kPixelData) {
		__updatePInfoPixelData(e);
	} else {
		log.debug('${_wb.wbb} writeIvrUndefined $e :${_wb.remaining}', 1);
	}
	_wb
		..code(e.code)
		..uint32(kUndefinedLength);
	__writeValueField(e);
	_wb.uint32(kSequenceDelimitationItem32BitLE);
	if (e.code == kPixelData) _pInfo.pixelDataEnd = _wb.wIndex;
	_pInfo.nUndefinedLengthElements++;
}


