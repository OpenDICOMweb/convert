// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isMaybeUndefinedLength(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLength(int vrIndex) =>
		vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax
                                                                 ;
Element _finishReadElement(int code, int eStart, Element e) {
  assert(_rb.checkIndex());
  // Elements are always read into the current dataset.
  // **** This is the only place they are added to the dataset.
  _cds.add(e);

  // Statistics
  if (statisticsEnabled) {
    _pInfo.lastElementRead = e;
    _pInfo.endOfLastElement = _rb.rIndex;
    if (e.isPrivate) _pInfo.nPrivateElements++;
    if (elementOffsetsEnabled) _offsets.add(eStart, _rb.rIndex, e);
    if ((code >> 16).isOdd) _pInfo.nPrivateElements++;
  }

  final eEnd = _rb.rIndex;
  _rb.eMsg(_elementCount, e, eStart, eEnd, -1);
  return e;
}

String failedTSErrorMsg(String path, Error x) => '''
Invalid Transfer Syntax: "$path"\nException: $x\n ${_rb.rrr}
    File length: ${_rb.lengthInBytes}\n${_rb.rrr} readFMI catch: $x
''';

String failedFMIErrorMsg(String path, Object x) => '''
Failed to read FMI: "$path"\nException: $x\n'
	  File length: ${_rb.lengthInBytes}\n${_rb.rrr} readFMI catch: $x');
''';

// Issue:
// **** Below this level is all for debugging and can be commented out for
// **** production.

void _showNext(int start) {
  if (_isEvr) {
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

void _showShortEVR(int start) {
  if (_rb.hasRemaining(8)) {
    final code = _rb.getCode(start);
    final vrCode = _rb.getUint16(start + 4);
    final vr = VR.lookupByCode(vrCode);
    final vfLengthField = _rb.getUint16(start + 6);
    log.debug('${_rb.rmm} **** Short EVR: ${dcm(code)} $vr vfLengthField: '
        '$vfLengthField');
  }
}

void _showLongEVR(int start) {
  if (_rb.hasRemaining(8)) {
    final code = _rb.getCode(start);
    final vrCode = _rb.getUint16(start + 4);
    final vr = VR.lookupByCode(vrCode);
    final vfLengthField = _rb.getUint32(start + 8);
    log.debug('${_rb.rmm} **** Long EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
  }
}

void _showIVR(int start) {
  if (_rb.hasRemaining(8)) {
    final code = _rb.getCode(start);
    final tag = Tag.lookupByCode(code);
    if (tag != null) log.debug(tag);
    final vfLengthField = _rb.getUint16(start + 4);
    log.debug('${_rb.rmm} **** IVR: ${dcm(code)} vfLengthField: $vfLengthField');
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
