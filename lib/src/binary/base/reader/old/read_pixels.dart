// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

/*

// _rIndex is at end of Value Field
Element _readPixelDataDefined(
    int code, int eStart, int vrIndex, int vfLengthField,
    EBytes ebMaker(ByteData bd)) {
	assert(vfLengthField != kUndefinedLength);
	log.debug2('${_rb.rbb} _readPixelDataDefined', 1);
	final endOfVF = _rb.rIndex + vfLengthField;

  _pInfo.pixelDataHadUndefinedLength = false;

  return _makePixelData(code, eStart, eLength, vrIndex, false, ebMaker);
}

/// There are only three VRs that use this: OB, OW, UN
// _rIndex is Just after vflengthField
Element _readPixelDataUndefined(int code, int eStart, int vrIndex, int vfLengthField) {
  assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
  // assert(vrIndex == kOBIndex || vrIndex == kOWIndex || vrIndex == kUNIndex);
  log.debug2('${_rb.rbb} _readPixelDataUndefined');


  final delimiter = _rb.getUint32(_rb.rIndex);
  if (delimiter == kItem32BitLE) {
    return __readPixelDataFragments(eStart, vfLengthField, vrIndex);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    return _makePixelData(eStart, endOfVF, vrIndex, true);
  }
}
*/

/// Reads an encapsulated (compressed) [kPixelData] [Element].
Element __readPixelDataFragments(
    int code, int eStart, int vfLengthField, int vrIndex, EBytes ebMaker(ByteData bd)) {
  log.debug('${_rb.rmm} _readPixelData Fragments', 1);
  assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
  __checkForOB(vrIndex, _rds.transferSyntax);

  final fragments = __readFragments();
  return _makePixelData(code, eStart, _rb.rIndex, vrIndex, true, ebMaker, fragments);
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
VFFragments __readFragments() {
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

    log.debug3('${_rb.ree}  length: ${endOfVF - startOfVF}', -1);
    iCode = _rb.uint32;
  } while (iCode != kSequenceDelimitationItem32BitLE);

  __checkItemLengthField(iCode);

  _pInfo.pixelDataHadFragments = true;
  final v = new VFFragments(fragments);
  log.debug3('${_rb.ree}  fragments: $v', -1);
  return v;
}

void __checkItemLengthField(int iCode) {
  final vfLengthField = _rb.uint32;
  if (vfLengthField != 0)
    _rb.warn('Pixel Data Sequence delimiter has non-zero '
        'value: $iCode/0x${hex32(iCode)} ${_rb.rrr}');
}
