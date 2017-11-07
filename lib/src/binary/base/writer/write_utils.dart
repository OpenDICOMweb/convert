// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

/*
bool _isSpecialVR(int vrIndex) =>
		vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;
*/

bool _isMaybeUndefinedVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isPixelDataVR(int vrIndex) => _isMaybeUndefinedVR(vrIndex);

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrVR(int vrIndex) => vrIndex >= kVRIvrIndexMin && vrIndex <= kVRIvrIndexMax;

void _writeItems(SQ sq) {
  final items = sq.items;
  for (var item in items) {
    log.debug('${_wb.wbb} Writing Item: $item', 1);
    if (item.hasULength && _keepUndefinedLengths) {
      _writeUndefinedLengthItem(item);
    } else {
      _writeDefinedLengthItem(item);
    }
    log.debug('${_wb.wee} Wrote Item: $item', -1);
  }
}

void _writeDefinedLengthItem(Item item) {
  _wb..uint32(kItem32BitLE)..uint32(item.lengthInBytes);
  item.forEach(_writeElement);
}

void _writeUndefinedLengthItem(Item item) {
  _wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
  item.forEach(_writeElement);
  _wb..uint32(kItemDelimitationItem)..uint32(0);
}

/// Writes the [delimiter] and a zero length field for the [delimiter].
/// The Write Index is advanced 8 bytes.
/// Note: There are four [Element]s ([SQ], [OB], [OW], and [UN]) plus
/// Items that might have an Undefined Length value(0xFFFFFFFF).
/// if [_eParams].removeUndefinedLengths is true this method should not be called.
void _writeDelimiter(int delimiter, [int lengthInBytes]) {
  lengthInBytes ??= 0;
  assert(_eParams.doConvertUndefinedLengths == false);
  _writeTagCode(delimiter);
  _wb.uint32(lengthInBytes);
}

void _writeTagCode(int code) {
  _wb..uint16(code >> 16)..uint16(code & 0xFFFF);
}

//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [file].
void _writeFile(Uint8List bytes, File file) {
  if (file == null) throw new ArgumentError('$file is not a File');
  file.writeAsBytesSync(bytes.buffer.asUint8List());
  log.debug('Wrote ${bytes.lengthInBytes} bytes to "${file.path}"');
}

//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [path].
void _writePath(Uint8List bytes, String path) {
  if (path == null || path.isEmpty) throw new ArgumentError();
  _writeFile(bytes, new File(path));
}

void _finishWritingElement(int start, int end, Element e) {
  _outputOffsets.add(start, end, e);
  _pInfo.nElements++;
  if (e.isPrivate) _pInfo.nPrivateElements++;
  _count++;
  _offset = _offset + (end - start);
  if (_elementOffsetsEnabled) {
    if (_inputOffsets.starts[_count] != start ||
        _inputOffsets.ends[_count] != end ||
        _inputOffsets.elements != e) throw 'Error';
  }
  log.debug('${_wb.wee} #$_count $_offset :${_wb.remaining}', -1);
}
