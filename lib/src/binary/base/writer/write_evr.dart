// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeEvrRootDataset(RootDataset rds, EncodingParameters eParams) {
  _rds = rds;
  _cds = rds;
  _isEvr = true;

  log.debug('${_wb.wbb} writeEvrRootDataset $rds :${_wb.remaining}');
  for (var e in rds.elements) {
    _writeEvrElement(e);
  }
//  rds.elements.forEach(_writeEvrElement);
  log.debug('${_wb.wee} writeEvrRootDataset  :${_wb.remaining}');
}

void _writeEvrElement(Element e, {ElementOffsets inputOffsets}) {
  _elementCount++;
  final eStart = _wb.wIndex;
  var vrIndex = e.vrIndex;

  if (_isSpecialVR(vrIndex)) {
    // This should not happen
    vrIndex = VR.kUN.index;
    _wb.warn('** vrIndex changed to VR.kUN.index');
  }

  log.debug('${_wb.wbb} #$_elementCount writeEvrElement $e :${_wb.remaining}', 1);
  if (_isEvrShortLengthVR(vrIndex)) {
    _writeShortEvr(e);
  } else if (_isEvrLongLengthVR(vrIndex)) {
    _writeLongEvr(e);
  } else if (_isSequenceVR(vrIndex)) {
    _writeEvrSQ(e);
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
    _writeEvrMaybeUndefined(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }

  if (e.eStart != eStart) {
    log.error('** e.eStart(${e.eStart} != eStart($eStart)');
  }
  if (e.eEnd != _wb.wIndex) {
    log.error('** e.eEnd(${e.eStart} != eEnd(${_wb.wIndex})');
  }

  _pInfo.nElements++;
  if (_statisticsEnabled) _doEndOfElementStats(eStart, _wb.wIndex, e);
  log.debug('${_wb.wee} #$_elementCount writeEvrElement ${e.dcm} ${e.keyword}', -2);
}

void _writeShortEvr(Element e) {
  log.debug('${_wb.wbb} writeShortEvr $e :${_wb.remaining}', 1);
  _wb
    ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(e.vfLength);
  __writeValueField(e);
  _pInfo.nShortElements++;
}

void _writeLongEvr(Element e) {
  log.debug('${_wb.wbb} writeLongEvr $e :${_wb.remaining}', 1);
  __reallyEvrWriteDefinedLength(e);
}

void _writeEvrMaybeUndefined(Element e) {
  log.debug('${_wb.wbb} writeEvrMaybeUndefined $e :${_wb.remaining}', 1);
  _pInfo.nMaybeUndefinedElements++;
  return (e.hadULength && !_eParams.doConvertUndefinedLengths)
      ? __reallyEvrWriteUndefinedLength(e)
      : __reallyEvrWriteDefinedLength(e);
}

void _writeEvrSQ(SQ e) {
  _pInfo.nSequences++;
  if (e.isPrivate) _pInfo.nPrivateSequences++;
  return (e.hadULength && !_eParams.doConvertUndefinedLengths)
      ? __writeEvrSQUndefinedLength(e)
      : __writeEvrSQDefinedLength(e);
}

void __writeEvrSQDefinedLength(SQ e) {
  log.debug('${_wb.wbb} writeEvrSQDefinedLength $e :${_wb.remaining}', 1);
  _pInfo.nDefinedLengthSequences++;
  final index = _outputOffsets.reserveSlot;
  final eStart = _wb.wIndex;
  final vlf = e.vfLength;
  final vlfOffset = _writeEvrLongHeader(e, e.vfLength);
  _writeItems(e.items, _writeEvrElement);
  final eEnd = _wb.wIndex;
  assert(e.vfLength + 12 == e.eEnd - e.eStart, '$vlf, $eEnd - $eStart');
  assert(vlf + 12 == (eEnd - eStart), '$vlf, $eEnd - $eStart');
  final vfLength = (eEnd - eStart) - 12;
  // print('$eStart - $eEnd vfLength: $vlf, $vfLength');
  _wb.setUint32(vlfOffset, vfLength);
  // print('evrDef: $eStart $eEnd, $e');
  _outputOffsets.insertAt(index, eStart, eEnd, e);
}

void __writeEvrSQUndefinedLength(SQ e) {
  final index = _outputOffsets.reserveSlot;
  final eStart = _wb.wIndex;
  log.debug('${_wb.wbb} writeEvrSQUndefinedLength $e :${_wb.remaining}', 1);
  _pInfo.nUndefinedLengthSequences++;
  _writeEvrLongHeader(e, kUndefinedLength);
  _writeItems(e.items, _writeEvrElement);
  _wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
  final eEnd = _wb.wIndex;
  // print('evrDef: $eStart $eEnd, $e');
  _outputOffsets.insertAt(index, eStart, eEnd, e);
}

void __reallyEvrWriteDefinedLength(Element e) {
  log.debug('${_wb.wmm} writeEvrUndefined $e :${_wb.remaining}');
  if (e.code == kPixelData) {}
  _writeEvrLongHeader(e, e.vfLength);
  __writeValueField(e);
  _pInfo.nLongElements++;
}

void __reallyEvrWriteUndefinedLength(Element e) {
  log.debug('${_wb.wmm} writeEvrUndefined $e :${_wb.remaining}');
  if (e.code == kPixelData) {
    __updatePInfoPixelData(e);
    _writeEncapsulatedPixelData(e);
  } else {
    _writeEvrLongHeader(e, kUndefinedLength);
    __writeValueField(e);
    _wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
  }
  _pInfo.nUndefinedLengthElements++;
}

int _writeEvrLongHeader(Element e, int vfLengthField) {
  _wb
    ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint32(vfLengthField);
  return _wb.wIndex - 4;
}

void _writeEncapsulatedPixelData(PixelData e) {
  __updatePInfoPixelData(e);
  _writeEvrLongHeader(e, e.vfLengthField);
  if (e.vfLengthField == kUndefinedLength) {
    for (final bytes in e.fragments.fragments) {
      _wb
        ..uint32(kItem32BitLE)
        ..uint32(bytes.lengthInBytes)
        ..bytes(bytes);
    }
    _wb
	    ..uint32(kSequenceDelimitationItem32BitLE)
	    ..uint32(0);
    _pInfo.pixelDataEnd = _wb.wIndex;
  }
}
