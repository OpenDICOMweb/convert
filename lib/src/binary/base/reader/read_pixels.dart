// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

// _rIndex is at end of Value Field
Element _readPixelDataDefined(int code, int eStart, int vrIndex, int vfLengthField, int
eLength) {
	log.debug2('${_rb.rbb} _readPixelData');
	_rIndex = _rIndex + vfLengthField;
	return _makePixelData(eStart, eLength, vrIndex);
}

/// There are only three VRs that use this: OB, OW, UN
// _rIndex is Just after vflengthField
Element _readPixelDataUndefined(
    int code, int eStart, int vrIndex, int vfLengthField) {
	assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
 // assert(vrIndex == kOBIndex || vrIndex == kOWIndex || vrIndex == kUNIndex);
  log.debug2('${_rb.rbb} _readPixelData');
  Element e;
  final item = _rb.uint32;
  if (item == kItem32BitLE) {
    e = _readFragmentedPixelData(eStart, vfLengthField, vrIndex);
  } else {
	  final eLength = _rIndex - eStart;
	  e = _makePixelData(eStart, eLength, vrIndex);
  }
  _beyondPixelData = true;
  _pixelDataEnd = _rIndex;
  return _finishReadElement(code, eStart, e);
}



/// Reads an encapsulated (compressed) [kPixelData] [Element].
Element _readFragmentedPixelData(int eStart, int vfLengthField, int vrIndex) {
	assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
	if (vrIndex != VR.kOB.index && vrIndex != VR.kUN.index) {
    final vr = VR.lookupByIndex(vrIndex);
    _rb.warn('Invalid VR($vr) for Encapsulated TS: $_tsUid ${_rb.rrr}');
    _hadParsingErrors = true;
  }
	log.debug2('${_rb.rbb} _readFragments');
  final fragments = _readFragments();
  final eLength = _rIndex - eStart;
	log.debug2('${_rb.ree} _readFragments');
  return _makePixelData(eStart, eLength, vrIndex, fragments);
}

VFFragments _readFragments() {
  final fragments = <Uint8List>[];
  var code = _rb.uint32;
  do {
    assert(code == kItem32BitLE, 'Invalid Item code: ${dcm(code)}');
    final vfLengthField = _rb.uint32;
    assert(vfLengthField != kUndefinedLength, 'Invalid length: ${dcm(vfLengthField)}');
    final startOfVF = _rIndex;
    _rIndex += vfLengthField;
    fragments.add(_rb.buffer.asUint8List(startOfVF, _rIndex - startOfVF));
    code = _rb.uint32;
  } while (code != kSequenceDelimitationItem32BitLE);
  // Read the Sequence Delimitation Item length field.
  final vfLengthField = _rb.uint32;
  if (vfLengthField != 0)
    _rb.warn('Pixel Data Sequence delimiter has non-zero '
        'value: $code/0x${hex32(code)} ${_rb.rrr}');
  return new VFFragments(fragments);
}

Element _makePixelData(int eStart, int eLength, int vrIndex,
    [VFFragments fragments]) {
  final bd = _rb.buffer.asByteData(eStart, eLength);
  final eb = (_isEVR) ? new EvrLong(bd) : new Ivr(bd);
  final e = makeBEPixelDataFromEBytes(eb, vrIndex, _tsUid, fragments);
  _currentDS.elements.add(e);
//  assert(checkRIndex());
  log.debug2('${_rb.ree} _makePixelData');
  return e;
}
