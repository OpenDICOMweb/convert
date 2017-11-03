// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeEvr(Element e) {
  final eStart = _blw.wIndex;
  final vrIndex = e.vrIndex;
  if (_isSequenceVR(vrIndex)) {
    _writeEvrSQ(e);
  } else if (_isMaybeUndefinedVR(vrIndex)) {
    _writeEvrMaybeUndefined(e);
  } else if (_isEvrLongVR(vrIndex)) {
    _writeLongEvr(e);
  } else if (_isEvrShortVR(vrIndex)) {
    _writeShortEvr(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }
  _finishWritingElement(eStart, _blw.wIndex, e);
}

void _writeEvrMaybeUndefined(Element e) {
  if (e.code == kPixelData) return _writeEvrPixelData(e);
  if (!_keepUndefinedLengths) return _writeLongEvr(e);
  _blw
    ..writeUint32(e.code)
    ..writeUint16(e.vrCode)
    ..writeUint16(0)
    ..writeUint32(kUndefinedLength);
  _writeValueField(e.vfBytes, e.vrIndex);
  _blw..writeUint32(kSequenceDelimitationItem);
}

/// Write [kPixelData] from [PixelData] [pd].
void _writeEvrPixelData(PixelData pd) {
  assert(_isPixelDataVR(pd.vrIndex));
  log.debug('${_blw.wbb} PixelData: $pd');
  _writeEvrMaybeUndefined(pd);
  log.debug('${_blw.wee}  @end');
}

void _writeLongEvr(Element e) {
  _writeEvrLongHeader(e, e.length);
  _writeValueField(e.vfBytes, e.vrIndex);
}

void _writeEvrUndefinedHeader(Element e) => _writeEvrLongHeader(e, kUndefinedLength);

void _writeEvrLongHeader(Element e, int vfLengthField) {
  _blw
    ..writeUint32(e.code)
    ..writeUint16(e.vrCode)
    ..writeUint16(0)
    ..writeUint32(vfLengthField);
}

void _writeShortEvr(Element e) {
  _blw
    ..writeUint32(e.code)
    ..writeUint16(e.vrCode)
    ..writeUint16(0)
    ..writeUint16(e.length);
  _writeValueField(e.vfBytes, e.vrIndex);
}

void _writeEvrSQ(SQ sq) {
  if (sq.hadULength && _keepUndefinedLengths) _writeEvrSQUndefined(sq);
  _writeEvrLongHeader(sq, sq.lengthInBytes);
  _writeItems(sq.items);
}

void _writeEvrSQUndefined(SQ sq) {
  _writeEvrUndefinedHeader(sq);
  _writeItems(sq.items);
  _blw.writeUint32(kSequenceDelimitationItem);
}

