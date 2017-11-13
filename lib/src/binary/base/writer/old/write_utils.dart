// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

bool _isSequence(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLength(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongLength(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortLength(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLength(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

/*
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
*/

/*
void _writeTagCode(int code) {
  _wb..uint16(code >> 16)..uint16(code & 0xFFFF);
}
*/

//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [file].
void _writeFile(Uint8List bytes, File file) {
  if (file == null) throw new ArgumentError('$file is not a File');
  file.writeAsBytesSync(bytes.buffer.asUint8List());
  log.debug('Wrote ${bytes.lengthInBytes} bytes to "${file.path}"');
}

/*
//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [path].
void _writePath(Uint8List bytes, String path) {
  if (path == null || path.isEmpty) throw new ArgumentError();
  _writeFile(bytes, new File(path));
}
*/

void _finishWritingElement(int start, int end, Element e) {
  _elementCount++;

  if (_statisticsEnabled) {
    _pInfo.nElements++;
    _pInfo.lastElementRead = e;
    _pInfo.endOfLastElement = _wb.wIndex;
    if (e.isPrivate) _pInfo.nPrivateElements++;

    if (_elementOffsetsEnabled && _inputOffsets != null) {
      _outputOffsets.add(start, end, e);

      final iStart = _inputOffsets.starts[_elementCount];
      final iEnd = _inputOffsets.ends[_elementCount];
      final ie = _inputOffsets.elements[_elementCount];
      if (iStart != start || iEnd != end || ie != e) {
        log..debug('''
**** Unequal Offset
	** $iStart to $iEnd read $e
  ** $start to $end wrote $e''');
        throw 'badOffset';
      }
    }
  }
  log.debug('${_wb.wee} #$_elementCount ${_wb.wIndex} :${_wb.remaining}', -1);
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
