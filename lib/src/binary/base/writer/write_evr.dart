// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeEvrRootDataset(RootDataset rds, EncodingParameters eParams) {
	log.debug('${_wb.wbb} _writeEvrRootDataset $rds :${_wb.remaining}', 1);
	_rds = rds;
	_cds = rds;
	_writeEvrDataset(rds, eParams);
	log.debug('${_wb.wee} _writeEvrRootDataset  :${_wb.remaining}', -1);
}

void _writeEvrDataset(Dataset ds, EncodingParameters _eParams) {
	assert(ds != null);
	final previousDS = _cds;
	_cds = ds;

	ds.elements.forEach(_writeEvrElement);
	_cds = previousDS;
}

void _writeEvrElement(Element e) {
	log.debug('${_wb.wbb} _writeEvrElement $e :${_wb.remaining}', 1);
  final eStart = _wb.wIndex;
  final vrIndex = e.vrIndex;
  if (_isEvrShortVR(vrIndex)) {
    _writeShortEvr(e);
  } else if (_isEvrLongVR(vrIndex)) {
    _writeLongEvr(e);
  } else if (_isSequenceVR(vrIndex)) {
    _writeEvrSQ(e);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    _writeEvrMaybeUndefined(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }
	log.debug('${_wb.wee} _writeEvrElement ${e.dcm} ${e.keyword}', -1);
  _finishWritingElement(eStart, _wb.wIndex, e);
}

void _writeShortEvr(Element e) {
	log.debug('${_wb.wbb} _writeShortEvr $e :${_wb.remaining}', 1);
  _wb
    ..uint32(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint16(e.length);
  _writeValueField(e);
}

void _writeLongEvr(Element e) {
	log.debug('${_wb.wbb} _writeLongEvr $e :${_wb.remaining}', 1);
  _wb
    ..uint32(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint32(e.vfLengthField);
  _writeValueField(e);
}

void _writeEvrMaybeUndefined(Element e) {
  if (e.code == kPixelData) return _writeEvrPixelData(e);
  if (!_keepUndefinedLengths) return _writeLongEvr(e);
  _wb
    ..uint32(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint32(kUndefinedLength);
  _writeValueField(e);
  _wb..uint32(kSequenceDelimitationItem);
}

void _writeEvrUndefined(Element e) {
	log.debug('${_wb.wbb} _writeEvrUndefined $e :${_wb.remaining}', 1);
	if (!_keepUndefinedLengths) return _writeLongEvr(e);
	_wb
		..uint32(e.code)
		..uint16(e.vrCode)
		..uint16(0)
		..uint32(kUndefinedLength);
	_writeValueField(e);
	_wb..uint32(kSequenceDelimitationItem);
}

/// Write [kPixelData] from [PixelData] [pd].
void _writeEvrPixelData(PixelData pd) {
	log.debug('${_wb.wbb} _writeEvrPixelData $pd :${_wb.remaining}', 1);
	_pInfo.pixelDataVR = pd.vr;
	_pInfo.pixelDataStart = _wb.wIndex;
	_pInfo.pixelDataLength = pd.vfLength;
  assert(_isPixelDataVR(pd.vrIndex));
  log.debug('${_wb.wmm} PixelData: $pd');
	_writeEvrUndefined(pd);
  log.debug('${_wb.wee}  @end');
}

void _writeEvrSQ(SQ e) => (e.hadULength && _keepUndefinedLengths)
    ? _writeEvrSQUndefined(e)
    : _writeEvrSQDefined(e);

void _writeEvrSQDefined(SQ e) {
	log.debug('${_wb.wbb} _writeEvrSQDefined $e :${_wb.remaining}', 1);
  _wb
    ..uint32(e.code)
    ..uint16(e.vrCode)
    ..uint16(0);
  final sqLengthOffset = _wb.wIndex;
  final start = _wb.move(4);
  _writeItems(e.items);
  _wb.setUint32(sqLengthOffset, _wb.wIndex - start);
}

void _writeEvrSQUndefined(SQ e) {
	log.debug('${_wb.wbb} _writeEvrSQUndefined $e :${_wb.remaining}', 1);
	_wb
		..uint32(e.code)
		..uint16(e.vrCode)
		..uint16(0)
		..uint32(kUndefinedLength);
  _writeItems(e.items);
  _wb.uint32(kSequenceDelimitationItem);
}
