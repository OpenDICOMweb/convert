// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeIvr(Element e) {
  final eStart = _blw.wIndex;
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
  _finishWritingElement(eStart, _blw.wIndex, e);
}

void _writeIvrSequence(SQ sq) {
	//TODO: handle replacing undefined lengths
	log.debug('${_blw.wbb} SQ $sq', 1);
	if (sq.hadULength && _keepUndefinedLengths) return _writeEvrMaybeUndefined(sq);
	_blw
		..writeUint32(sq.code)
		..writeUint32(sq.length);
	if (sq.items.isNotEmpty) _writeItems(sq);
	if (sq.hadULength) _writeDelimiter(kSequenceDelimitationItem);
	_nSequences++;
	if (sq.isPrivate) _nPrivateSequences++;
	log.debug('${_blw.wee} SQ', -1);
}


void _writeIvrMaybeUndefined(Element e) {
  if (e.code == kPixelData) return _writeIvrPixelData(e);
  if (!_keepUndefinedLengths) return _writeSimpleIvr(e);
  _blw..writeUint32(e.code)..writeUint32(kUndefinedLength);
  _writeValueField(e.vfBytes, e.vrIndex);
  _blw.writeUint32(kSequenceDelimitationItem);
}

/// Write [kPixelData] from [PixelData] [pd].
void _writeIvrPixelData(PixelData pd) {
	assert(_isPixelDataVR(pd.vrIndex));
	log.debug('${_blw.wbb} PixelData: $pd');
	_writeIvrMaybeUndefined(pd);
	log.debug('${_blw.wee}  @end');
}

void _writeSimpleIvr(Element e) {
  _blw
    ..writeUint32(e.code)
    ..writeUint32(e.length);
  _writeValueField(e.vfBytes, e.vrIndex);
}
