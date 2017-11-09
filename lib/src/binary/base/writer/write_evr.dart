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

  log.debug('${_wb.wbb} _writeEvrRootDataset $rds :${_wb.remaining}', 1);
  rds.elements.forEach(_writeEvrElement);
  log.debug('${_wb.wee} _writeEvrRootDataset  :${_wb.remaining}', -1);
}

void _writeEvrItems(SQ sq) {
	final items = sq.items;
	for (var item in items) {
		final parentDS = _cds;
		_cds = item;

		log.debug('${_wb.wbb} Writing Item: $item', 1);
		if (item.hasULength && !_eParams.doConvertUndefinedLengths) {
			_writeEvrItemUndefined(item);
		} else {
			_writeEvrItemDefined(item);
		}
		_cds = parentDS;

		log.debug('${_wb.wee} Wrote Item: $item', -1);
	}
}

void _writeEvrItemUndefined(Item item) {
	_wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
	item.forEach(_writeEvrElement);
	_wb..uint32(kItemDelimitationItem)..uint32(0);
}

void _writeEvrItemDefined(Item item) {
	_wb..uint32(kItem32BitLE)..uint32(item.lengthInBytes);
	item.forEach(_writeEvrElement);
}

void _writeEvrElement(Element e, {ElementOffsets inputOffsets}) {
  log.debug('${_wb.wbb} _writeEvrElement $e :${_wb.remaining}', 1);
  final eStart = _wb.wIndex;
  final vrIndex = e.vrIndex;
  if (_isEvrShortLength(vrIndex)) {
    _writeShortEvr(e);
  } else if (_isEvrLongLength(vrIndex)) {
    _writeLongEvr(e);
  } else if (_isSequence(vrIndex)) {
    _writeEvrSQ(e);
  } else if (_isMaybeUndefinedLength(vrIndex)) {
    _writeEvrMaybeUndefined(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }
  log.debug('${_wb.wee} _writeEvrElement ${e.dcm} ${e.keyword}', -1);
  _pInfo.nElements++;
  _finishWritingElement(eStart, _wb.wIndex, e);
}

void _writeShortEvr(Element e) {
  log.debug('${_wb.wbb} _writeShortEvr $e :${_wb.remaining}', 1);
  _wb
    ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(e.vfLength);
  _writeValueField(e);
  _pInfo.nShortElements++;
}

void _writeLongEvr(Element e) {
  log.debug('${_wb.wbb} _writeLongEvr $e :${_wb.remaining}', 1);
  _wb
	  ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint32(e.vfLengthField);
  _writeValueField(e);
  _pInfo.nLongElements++;
}

void _writeEvrMaybeUndefined(Element e) {
  if (e.code == kPixelData) return _writeEvrPixelData(e);
  _pInfo.nMaybeUndefinedElements++;
  return (!e.hadULength ||_eParams.doConvertUndefinedLengths)
         ? _writeLongEvr(e)
         : _writeEvrUndefined(e);
}

void _writeEvrUndefined(Element e) {
  log.debug('${_wb.wbb} _writeEvrUndefined $e :${_wb.remaining}', 1);
  _wb
	  ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint32(kUndefinedLength);
  _writeValueField(e);
  _wb..uint32(kSequenceDelimitationItem);
  _pInfo.nUndefinedElements++;
}

/// Write [kPixelData] from [PixelData] [pd].
void _writeEvrPixelData(PixelData pd) {
  log.debug('${_wb.wbb} _writeEvrPixelData $pd :${_wb.remaining}', 1);
  _pInfo.pixelDataVR = pd.vr;
  _pInfo.pixelDataStart = _wb.wIndex;
  _pInfo.pixelDataLength = pd.vfLength;

  assert(_isMaybeUndefinedLength(pd.vrIndex));
  log.debug('${_wb.wmm} PixelData: $pd');
  _writeEvrUndefined(pd);
  log.debug('${_wb.wmm}  @End of Pixel Data');
}

void _writeEvrSQ(SQ e) {
  _pInfo.nSequences++;
  if (e.isPrivate) _pInfo.nPrivateSequences++;
  return (e.hadULength && !_eParams.doConvertUndefinedLengths)
      ? _writeEvrSQUndefined(e)
      : _writeEvrSQDefined(e);
}

void _writeEvrSQDefined(SQ e) {
  log.debug('${_wb.wbb} _writeEvrSQDefined $e :${_wb.remaining}', 1);
  _wb
	  ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(0);
  final sqLengthOffset = _wb.wIndex;
  final start = _wb.move(4);
  _writeEvrItems(e.items);
  _wb.setUint32(sqLengthOffset, _wb.wIndex - start);
  _pInfo.nDefinedSequences++;
}

void _writeEvrSQUndefined(SQ e) {
  log.debug('${_wb.wbb} _writeEvrSQUndefined $e :${_wb.remaining}', 1);
  _wb
	  ..code(e.code)
    ..uint16(e.vrCode)
    ..uint16(0)
    ..uint32(kUndefinedLength);
  _writeEvrItems(e.items);
  _wb.uint32(kSequenceDelimitationItem);
  _pInfo.nUndefinedSequences++;
}


