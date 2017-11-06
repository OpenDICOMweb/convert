// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeIvrRootDataset(RootDataset rds, EncodingParameters eParams) {
	_rds = rds;
	_cds = rds;
	_writeEvrDataset(rds, eParams);
}

void _writeIvrDataset(Dataset ds, EncodingParameters _eParams) {
	assert(ds != null);
	final previousDS = _cds;
	_cds = ds;


	ds.elements.forEach(_writeElement);
	_cds = previousDS;
}

void _writeIvr(Element e) {
  final eStart = _wb.wIndex;
  final vrIndex = e.vrIndex;
  if (_isSequenceVR(vrIndex)) {
    _writeIvrSequence(e);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    _writeIvrMaybeUndefined(e);
  } else if (_isIvrVR(vrIndex)) {
    _writeSimpleIvr(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }
  _finishWritingElement(eStart, _wb.wIndex, e);
}

void _writeIvrSequence(SQ sq) {
	//TODO: handle replacing undefined lengths
	log.debug('${_wb.wbb} SQ $sq', 1);
	if (sq.hadULength && _keepUndefinedLengths) return _writeEvrMaybeUndefined(sq);
	_wb
		..uint32(sq.code)
		..uint32(sq.length);
	if (sq.items.isNotEmpty) _writeItems(sq);
	if (sq.hadULength) _writeDelimiter(kSequenceDelimitationItem);
	_parseInfo.nSequences++;
	if (sq.isPrivate) _parseInfo.nPrivateSequences++;
	log.debug('${_wb.wee} SQ', -1);
}


void _writeIvrMaybeUndefined(Element e) {
  if (e.code == kPixelData) return _writeIvrPixelData(e);
  if (!_keepUndefinedLengths) return _writeSimpleIvr(e);
  _wb..uint32(e.code)..uint32(kUndefinedLength);
  _writeValueField(e);
  _wb.uint32(kSequenceDelimitationItem);
}

/// Write [kPixelData] from [PixelData] [pd].
void _writeIvrPixelData(PixelData pd) {
	assert(_isPixelDataVR(pd.vrIndex));
	log.debug('${_wb.wbb} PixelData: $pd');
	_writeIvrMaybeUndefined(pd);
	log.debug('${_wb.wee}  @end');
}

void _writeSimpleIvr(Element e) {
  _wb
    ..uint32(e.code)
    ..uint32(e.length);
  _writeValueField(e);
}
