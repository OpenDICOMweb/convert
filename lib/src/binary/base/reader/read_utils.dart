// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

int _readCode() {
  final code = _readTagCode();
  if (code == 0) {
    _skip(-4); // undo readTagCode
    _zeroEncountered(code);
    return null;
  }
  if (code > 0x3000 && Tag.isGroupLengthCode(code)) _hadGroupLengths = true;
  return code;
}

/*
/// Read an Element (not SQ)  with a 32-bit [vfLengthField], that might have
/// kUndefinedValue.
Element _readMaybeUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  if (vfLengthField == kUndefinedLength) {
    final endOfVF = _findEndOfULengthVF();
    final eLength = endOfVF - eStart;
    _rIndex = endOfVF + 8;
    return _finishLong(code, eStart, vrIndex, vfLengthField, eLength);
  } else {
    return _readLong(code, eStart, vrIndex, vfLengthField);
  }
}


/// Read an Element (not SQ) with a 32-bit [vfLengthField], but that cannot
/// have kUndefinedValue.
Element _readLong(int code, int eStart, int vrIndex, int vfLengthField) {
  final eLength = _rIndex - eStart;
  _rIndex = _rIndex + vfLengthField;
  return _finishLong(code, eStart, vrIndex, vfLengthField, eLength);
}

/// Finish reading a 32-bit (non SQ) Element.
Element _finishLong(int code, int eStart, int vrIndex, int vfLengthField, int eLength) {
  if (code == kPixelData) {
    return _readPixelData(eStart, vfLengthField, vrIndex, eLength);
  } else {
    final bd = _rootBD.buffer.asByteData(eStart, eLength);
    final eb = new EvrLong(bd);
    return elementMaker(eb, vrIndex);
  }
}
*/
/// Reads the [kUndefinedLength] Value Field until the
/// kSequenceDelimiter is found. _Note_: Since the Value
/// Field is 16-bit aligned, it must be checked 16 bits at a time.
int _findEndOfULengthVF() {
  log.down;
  //  log.debug1('$rbb findEndOfULengthVF');
  while (_isReadable()) {
    if (_readUint16() != kDelimiterFirst16Bits) continue;
    if (_readUint16() != kSequenceDelimiterLast16Bits) continue;
    break;
  }
  if (!_isReadable()) {
    throw new EndOfDataError('_findEndOfVF');
  }
  final delimiterLength = _readUint32();
  if (delimiterLength != 0) _delimiterLengthWarning(delimiterLength);
  final endOfVF = _rIndex - 8;
  //  log.debug1('$ree   endOfVR($endOfVF) eEnd($_rIndex) @end');
  log.up;
  return endOfVF;
}

Element _finishReadElement(int code, int eStart, Element e) {
  assert(_checkRIndex());
  // Elements are always read into the current dataset.
  _currentDS.add(e);
  _lastElementRead = e;

  // Statistics
  if (statisticsEnabled) {
    _nElementsRead++;
    _endOfLastValueRead = _rIndex;
    if (elementOffsetsEnabled) _offsets.add(eStart, _rIndex, e);
    _lastTopLevelElementRead = e;
    _lastElementCode = code;
    if ((code >> 16).isOdd) _nPrivateElementsRead++;
  }
  log.info('element: $e');
  return e;
}

/// Reads a group and element and combines them into a Tag.code.
int _readTagCode() {
  assert(_rIndex.isEven);
  final code = _peekTagCode();
  _rIndex += 4;
  return code;
}

/// Peek at next tag - doesn't move the [_rIndex].
int _peekTagCode() {
  assert(_rIndex.isEven);
  final group = _getUint16(_rIndex);
  final elt = _getUint16(_rIndex + 2);
  return (group << 16) + elt;
}

int _readUint16() {
  assert(_rIndex.isEven);
  final v = _getUint16(_rIndex);
  _rIndex += 2;
  return v;
}

int _readUint32() {
  assert(_rIndex.isEven);
  final v = _getUint32(_rIndex);
  _rIndex += 4;
  return v;
}

int _getUint32(int offset) {
  assert(offset.isEven);
  return _rootBD.getUint32(offset, Endianness.LITTLE_ENDIAN);
}

int _getUint16(int offset) {
  assert(offset.isEven);
  return _rootBD.getUint16(offset, Endianness.LITTLE_ENDIAN);
}

int _getUint8(int offset) => _rootBD.getUint8(offset);

int _skip(int n) {
  assert(_rIndex.isEven);
   _rIndex = _rIndex + n;
  return RangeError.checkValidRange(0, _rIndex, _rootBD.lengthInBytes);
}

//TODO: put _checkIndex in appropriate places
bool _checkRIndex() {
  if (_rIndex.isOdd) {
    final msg = 'Odd Lenth Value Field at @$_rIndex - incrementing';
    _warn('$msg $_rrr');
    _skip(1);
    _nOddLengthValueFields++;
    if (throwOnError) throw msg;
  }
  return true;
}

void _warn(String msg) {
  final s = '**   $msg $_rrr';
  exceptions.add(s);
  log.warn(s);
}

void _error(String msg) {
  final s = '**** $msg $_rrr';
  exceptions.add(s);
  log.error(s);
}

//  String _readUtf8String(int length) => UTF8.decode(_readChars(length));

// **** these next four are utilities for logger
/// The current readIndex as a string.
String get _rrr => 'R@$_rIndex';

/// The beginning of reading an [Element] or [Item].
String get rbb => '> $_rrr';

/// In the middle of reading an [Element] or [Item]
String get rmm => '| $_rrr  ';

/// The end of reading an [Element] or [Item]
String get ree => '< $_rrr  ';

String get pad => ''.padRight('$_rrr'.length);

bool _checkAllZeros(int start, int end) {
  for (var i = start; i < end; i++) if (_getUint8(i) != 0) return false;
  return true;
}

//Enhancement: make this method do more diagnosis.
/// Returns true if there are only trailing zeros at the end of the
/// Object being parsed.
Element _zeroEncountered(int code) {
  final msg = (_beyondPixelData) ? 'after kPixelData' : 'before kPixelData';
  _warn('Zero encountered $msg $_rrr');
  throw new EndOfDataError('Zero encountered $msg $_rrr');
}

// Issue:
// **** Below this level is all for debugging and can be commented out for
// **** production.

void _showNext(int start) {
  if (_isEVR) {
    _showShortEVR(start);
    _showLongEVR(start);
    _showIVR(start);
    _showShortEVR(start + 4);
    _showLongEVR(start + 4);
    _showIVR(start + 4);
  } else {
    _showIVR(start);
    _showIVR(start + 4);
  }
}

int _getCode(int start) {
  if (_hasRemaining(4)) {
    final group = _getUint16(start);
    final elt = _getUint16(start);
    return group << 16 & elt;
  }
  return null;
}

void _showShortEVR(int start) {
  if (_hasRemaining(8)) {
    final code = _getCode(start);
    final vrCode = _getUint16(start + 4);
    final vr = VR.lookupByCode(vrCode);
    final vfLengthField = _getUint16(start + 6);
    log.debug('$rmm **** Short EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
  }
}

void _showLongEVR(int start) {
  if (_hasRemaining(8)) {
    final code = _getCode(start);
    final vrCode = _getUint16(start + 4);
    final vr = VR.lookupByCode(vrCode);
    final vfLengthField = _getUint32(start + 8);
    log.debug('$rmm **** Long EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
  }
}

void _showIVR(int start) {
  if (_hasRemaining(8)) {
    final code = _getCode(start);
    final tag = Tag.lookupByCode(code);
    if (tag != null) log.debug(tag);
    final vfLengthField = _getUint16(start + 4);
    log.debug('$rmm **** IVR: ${dcm(code)} vfLengthField: $vfLengthField');
  }
}

String toVFLength(int vfl) => 'vfLengthField($vfl, ${hex32(vfl)})';
String toHadULength(int vfl) =>
    'HadULength(${(vfl == kUndefinedLength) ? 'true': 'false'})';

/* Enhancement:
  void _printTrailingData(int start, int length) {
    for (var i= start; i < start + length; i += 4) {
      final x = _getUint16(i);
      final y = _getUint16(i + 2);
      final z = _getUint32(i);
      final xx = toHex8(x);
      final yy = toHex16(y);
      final zz = hex32(z);
      print('@$i: 16($x, $xx) | $y, $yy) 32($z, $zz)');
    }
  }
*/

/*  Enhancement: Flush if not needed
  bool _doLog = true;


  String get _XCode => '${dcm(_code)}';
  String get _XvrCode => 'vrCode(${toHex16(_vrCode)})';
  String get _XvfLengthField => 'vfLengthField(${hex32(_vfLengthField)})';


  _start(String name, [int code, int start]) {
    if (!_doLog) return;
    //  log.debug('$rbb $name${dcm(code)} $_evrString ', 1);
  }

  _end(String name, Element e, [String msg]) {
    if (!_doLog) return;
    //  log.debug('$ree $_nElementsRead: $e @end', -1);
  }
*/
