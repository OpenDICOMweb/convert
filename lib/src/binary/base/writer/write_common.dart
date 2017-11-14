// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongLengthVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortLengthVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

int itemCount;
void _writeItems(List<Item> items, void writer(Element e)) {
  itemCount = 0;
  log.debug('${_wb.wbb} Writing ${items.length} Items', 1);
  for (var item in items) {
    final parentDS = _cds;
    _cds = item;

    log.debug('${_wb.wbb} Writing Item: $item', 1);
    ((item.hasULength && !_eParams.doConvertUndefinedLengths))
        ? _writeItemUndefinedLength(item, writer, itemCount)
        : _writeItemDefinedLength(item, writer, itemCount);

    _cds = parentDS;
    itemCount++;
    log.debug('${_wb.wee} Wrote Item: $item', -1);
  }
  log.debug('${_wb.wee} Wrote $itemCount Items', -1);
}

void _writeItemUndefinedLength(Item item, void writer(Element e), int number) {
  log.debug('${_wb.wbb} Writing item #$itemCount', 1);
  _wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
  for (var e in item.elements) {
    log.debug('${_wb.wbb} $e');
    writer(e);
  }
  // item.elements.forEach(writer);
  _wb..uint32(kItemDelimitationItem32BitLE)..uint32(0);
  log.debug('${_wb.wee} Wrote item #$itemCount', -1);
}

void _writeItemDefinedLength(Item item, void writer(Element e), int number) {
  _wb..uint32(kItem32BitLE)..uint32(item.vfLength);
  for (var e in item.elements) {
    log.debug('${_wb.wbb}  $e');
    writer(e);
  }
//  item.elements.forEach(writer);
}

//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [file].
void _writeFile(Uint8List bytes, File file) {
  if (file == null) throw new ArgumentError('$file is not a File');
  file.writeAsBytesSync(bytes.buffer.asUint8List());
  log.debug('Wrote ${bytes.lengthInBytes} bytes to "${file.path}"');
}

void _doEndOfElementStats(int start, int end, Element e) {
  _pInfo.nElements++;
  _pInfo.lastElementRead = e;
  _pInfo.endOfLastElement = end;
  if (e.isPrivate) _pInfo.nPrivateElements++;
  if (e is SQ) {
    _pInfo.endOfLastSequence = end;
    _pInfo.lastSequenceRead = e;
  }

  if (e is! SQ && _elementOffsetsEnabled && !_rds.hasDuplicates) {
    _outputOffsets.add(start, end, e);

    final iStart = _inputOffsets.starts[_elementCount];
    final iEnd = _inputOffsets.ends[_elementCount];
    final ie = _inputOffsets.elements[_elementCount];
    if (iStart != start || iEnd != end || ie != e) {
      log.debug('''
**** Unequal Offset at Element $_elementCount
	** $iStart to $iEnd read $e
  ** $start to $end wrote $e''');
      throw 'badOffset';
    }
  }
}

void __updatePInfoPixelData(Element e) {
  log
    ..debug('Pixel Data: ${e.info}')
    ..debug('vfLength: ${e.vfLength}')
    ..debug('vfLengthField: ${e.vfLengthField}')
    ..debug('fragments: ${e.fragments.info}');
  _pInfo.pixelDataVR = e.vr;
  _pInfo.pixelDataStart = _wb.wIndex;
  _pInfo.pixelDataLength = e.vfLength;
  _pInfo.pixelDataHadFragments = e.fragments != null;
  _pInfo.pixelDataHadUndefinedLength = e.vfLengthField == kUndefinedLength;
}

void showOffsets() {
  log
    ..info(' input offset length: ${_inputOffsets.length}')
    ..info('output offset length: ${_outputOffsets.length}');
  for (var i = 0; i < _inputOffsets.length; i++) {
    final iStart = _inputOffsets.starts[i];
    final iEnd = _inputOffsets.ends[i];
    final ioe = _inputOffsets.elements[i];
    final oStart = _outputOffsets.starts[i];
    final oEnd = _outputOffsets.ends[i];
    final ooe = _outputOffsets.elements[i];

    log
      ..info('iStart: $iStart iEnd: $iEnd e: $ioe')
      ..info('oStart: $oStart iEnd: $oEnd e: $ooe');
  }
}
