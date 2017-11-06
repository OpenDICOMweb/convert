// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

Element _makePixelData(int eStart, int eLength, int vrIndex, [VFFragments fragments]) {
	_pInfo.pixelDataVR = VR.lookupByIndex(vrIndex);
  _pInfo.pixelDataStart = eStart;
  _pInfo.pixelDataLength = eLength;
  final bd = _rb.buffer.asByteData(eStart, eLength);
  final eb = (_isEvr) ? new EvrLong(bd) : new Ivr(bd);
  final e = makeBEPixelDataFromEBytes(eb, vrIndex, _rds.transferSyntax, fragments);
  log.debug3('${_rb.rmm} _makePixelData: $eb');
  return _finishReadElement(kPixelData, eStart, e);
}

// _rIndex is at end of Value Field
Element _readPixelDataDefined(
    int code, int eStart, int vrIndex, int vfLengthField, int eLength) {
  log.debug2('${_rb.rbb} _readPixelDataDefined', 1);
  final e = _makePixelData(eStart, eLength, vrIndex);
  log.debug2('${_rb.ree} _readPixelDataDefined', -1);
  _pInfo.pixelDataHadUndefinedLength = false;
  return e;
}

/// There are only three VRs that use this: OB, OW, UN
// _rIndex is Just after vflengthField
Element _readPixelDataUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
  // assert(vrIndex == kOBIndex || vrIndex == kOWIndex || vrIndex == kUNIndex);
  log.debug2('${_rb.rbb} _readPixelDataUndefined');
  Element e;
  final delimiter = _rb.getUint32(_rb.rIndex);
  if (delimiter == kItem32BitLE) {
  	_pInfo.pixelDataHadFragments = true;
    e = _readPixelDataFragments(eStart, vfLengthField, vrIndex);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    e = _makePixelData(eStart, endOfVF - eStart, vrIndex);
  }
  _beyondPixelData = true;
  _pInfo.pixelDataHadUndefinedLength = true;
  return _finishReadElement(code, eStart, e);
}

/// Reads an encapsulated (compressed) [kPixelData] [Element].
Element _readPixelDataFragments(int eStart, int vfLengthField, int vrIndex) {
  log.debug('${_rb.rbb} _readPixelData Fragments', 1);
  assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
  __checkForOB(vrIndex, _rds.transferSyntax);

  final fragments = _readFragments();
  final eLength = _rb.rIndex - eStart;
  final e = _makePixelData(eStart, eLength, vrIndex, fragments);
  log.debug('${_rb.ree} $e');
  return e;
}

void __checkForOB(int vrIndex, TransferSyntax ts) {
  if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
    final vr = VR.lookupByIndex(vrIndex);
    _rb.warn('Invalid VR($vr) for Encapsulated TS: $ts ${_rb.rrr}');
    _pInfo.hadParsingErrors = true;
  }
}

/// Read Pixel Data Fragments.
/// They each start with an Item Delimiter followed by the 32-bit Item
/// length field, which may not have a value of kUndefinedValue.
VFFragments _readFragments() {
  final fragments = <Uint8List>[];
  var iCode = _rb.uint32;
  do {
    assert(iCode == kItem32BitLE, 'Invalid Item code: ${dcm(iCode)}');
    final vfLengthField = _rb.uint32;
    log.debug3('${_rb.rbb} _readFragment ${dcm(iCode)} length: $vfLengthField', 1);
    assert(vfLengthField != kUndefinedLength, 'Invalid length: ${dcm(vfLengthField)}');

    final startOfVF = _rb.rIndex;
    final endOfVF = _rb + vfLengthField;
    fragments.add(_rb.buffer.asUint8List(startOfVF, endOfVF - startOfVF));

    log.debug3('${_rb.rmm}  length: ${endOfVF - startOfVF}');
    iCode = _rb.uint32;
  } while (iCode != kSequenceDelimitationItem32BitLE);

  __checkItemLengthField(iCode);

  final v = new VFFragments(fragments);
  log.debug3('${_rb.rmm}  fragments: $v', -1);
  return v;
}

void __checkItemLengthField(int iCode) {
  final vfLengthField = _rb.uint32;
  if (vfLengthField != 0)
    _rb.warn('Pixel Data Sequence delimiter has non-zero '
        'value: $iCode/0x${hex32(iCode)} ${_rb.rrr}');
}
