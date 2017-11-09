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

  for (var e in rds.elements) {
    if (e.code < 0x00030000) {
      print(e);
      print('${_wb.www}');
      _writeEvrElement(e);
      print('${_wb.www}');
    } else {
      print(e);
      print('${_wb.www}');
      _writeIvrElement(e);
      print('${_wb.www}');
    }
  }
  log.debug('${_wb.wee} _writeIvrRootDataset  :${_wb.remaining}', -1);
}

void _writeIvrItems(SQ sq) {
  final items = sq.items;
  for (var item in items) {
    final parentDS = _cds;
    _cds = item;

    log.debug('${_wb.wbb} Writing Item: $item', 1);
    if (item.hasULength && !_eParams.doConvertUndefinedLengths) {
      _writeIvrItemUndefined(item);
    } else {
      _writeIvrItemDefined(item);
    }
    _cds = parentDS;

    log.debug('${_wb.wee} Wrote Item: $item', -1);
  }
}

void _writeIvrItemUndefined(Item item) {
  _wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
  item.forEach(_writeIvrElement);
  _wb..uint32(kItemDelimitationItem)..uint32(0);
}

void _writeIvrItemDefined(Item item) {
  _wb..uint32(kItem32BitLE)..uint32(item.lengthInBytes);
  item.forEach(_writeIvrElement);
}

void _writeIvrElement(Element e) {
  log.debug('${_wb.wbb} _writeIvrElement $e :${_wb.remaining}', 1);
  final eStart = _wb.wIndex;
  final vrIndex = e.vrIndex;

  if (_isIvrDefinedLength(vrIndex)) {
    _writeSimpleIvr(e);
  } else if (_isSequence(vrIndex)) {
    _writeIvrSQ(e);
  } else if (_isMaybeUndefinedLength(vrIndex)) {
    _writeIvrMaybeUndefined(e);
  } else if (_isSpecialVR(vrIndex)) {
    _writeIvrMaybeUndefined(e);
  } else {
    throw new ArgumentError('Invalid VR: $e');
  }
  log.debug('${_wb.wee} _writeIvrElement ${e.dcm} ${e.keyword}', -1);
  _pInfo.nElements++;
  _finishWritingElement(eStart, _wb.wIndex, e);
}

void _writeSimpleIvr(Element e) {
  log.debug('${_wb.wbb} _writeSimpleIvr $e :${_wb.remaining}', 1);
  _wb
    ..code(e.code)
    ..uint32(e.vfLength);
  _writeValueField(e);
  _pInfo.nLongElements++;
}

void _writeIvrMaybeUndefined(Element e) {
  _pInfo.nMaybeUndefinedElements++;
  if (e.code == kPixelData) return _writeIvrPixelData(e);
  return (e.hadULength && _eParams.doConvertUndefinedLengths)
      ? _writeSimpleIvr(e)
      : _writeIvrUndefined(e);
}

void _writeIvrUndefined(Element e) {
  log.debug('${_wb.wbb} _writeIvrUndefined $e :${_wb.remaining}', 1);
  _wb
    ..code(e.code)
    ..uint32(kUndefinedLength);
  _writeValueField(e);
  _wb.uint32(kSequenceDelimitationItem);
  _pInfo.nUndefinedElements++;
}

/// Write [kPixelData] from [PixelData] [e].
void _writeIvrPixelData(PixelData e) {
  log.debug('${_wb.wbb} _writeIvrPixelData $e :${_wb.remaining}', 1);
  _pInfo.pixelDataVR = e.vr;
  _pInfo.pixelDataStart = _wb.wIndex;
  _pInfo.pixelDataLength = e.vfLength;

  assert(_isMaybeUndefinedLength(e.vrIndex));

  if (e.hadULength && _eParams.doConvertUndefinedLengths) {
    _writeSimpleIvr(e);
  } else {
    _writeIvrUndefined(e);
  }
  log.debug('${_wb.wmm}  @End of Pixel Data');
}

void _writeIvrSQ(SQ e) {
  _pInfo.nSequences++;
  if (e.isPrivate) _pInfo.nPrivateSequences++;
  return (e.hadULength && !_eParams.doConvertUndefinedLengths)
      ? _writeIvrSQUndefined(e)
      : _writeIvrSQDefined(e);
}

void _writeIvrSQDefined(SQ e) {
  log.debug('${_wb.wbb} _writeIvrSQDefined $e :${_wb.remaining}', 1);
  _wb.code(e.code);
  final sqLengthOffset = _wb.wIndex;
  final start = _wb.move(4);
  if (e.items.isNotEmpty) _writeIvrItems(e);
  _wb.setUint32(sqLengthOffset, _wb.wIndex - start);
  _pInfo.nDefinedSequences++;
}

void _writeIvrSQUndefined(SQ e) {
  log.debug('${_wb.wbb} _writeIvrSQUndefined $e :${_wb.remaining}', 1);
  _wb
    ..code(e.code)
    ..uint32(kUndefinedLength);
  if (e.items.isNotEmpty) _writeIvrItems(e);
  _wb.uint32(kSequenceDelimitationItem);
  _pInfo.nUndefinedSequences++;
}
