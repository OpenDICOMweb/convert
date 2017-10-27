// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

Element _readPixelData(int eStart, int vfLengthField, int vrIndex, int eLength) {
  assert(vrIndex == VR.kOB.index || vrIndex == VR.kOW.index || vrIndex == VR.kUN.index);
  _pixelDataStart = _rIndex;
  _pixelDataVR = VR.lookup(vrIndex);
  int eLength;
  Element e;
  final item = _getUint32(_rIndex);
  if (item == kItem32BitLE) {
    e = _readFragmentedPixelData(eStart, vfLengthField, vrIndex);
  } else {
    e = _makePixelData(eStart, eLength, vrIndex);
  }
  _beyondPixelData = true;
  _pixelDataEnd = _rIndex;
  return e;
}

/// Reads an encapsulated (compressed) [kPixelData] [Element].
Element _readFragmentedPixelData(int eStart, int vfLengthField, int vrIndex) {
  if (vrIndex != VR.kOB.index && vrIndex != VR.kUN.index) {
    final vr = VR.lookup(vrIndex);
    _warn('Invalid VR($vr) for Encapsulated TS: $_tsUid $_rrr');
    _hadParsingErrors = true;
  }
  final fragments = _readFragments();
  final eLength = _rIndex - eStart;
  return _makePixelData(eStart, eLength, vrIndex, fragments);
}

VFFragments _readFragments() {
  final fragments = <Uint8List>[];
  var code = _readUint32();
  do {
    assert(code == kItem32BitLE, 'Invalid Item code: ${dcm(code)}');
    final vfLengthField = _readUint32();
    assert(vfLengthField != kUndefinedLength, 'Invalid length: ${dcm(vfLengthField)}');
    final startOfVF = _rIndex;
    _rIndex += vfLengthField;
    fragments.add(_rootBD.buffer.asUint8List(startOfVF, _rIndex - startOfVF));
    code = _readUint32();
  } while (code != kSequenceDelimitationItem32BitLE);
  // Read the Sequence Delimitation Item length field.
  final vfLengthField = _readUint32();
  if (vfLengthField != 0)
    _warn('Pixel Data Sequence delimiter has non-zero '
        'value: $code/0x${hex32(code)} $_rrr');
  return new VFFragments(fragments);
}

Element _makePixelData(int eStart, int eLength, int vrIndex, [VFFragments fragments]) {
	final bd = _rootBD.buffer.asByteData(eStart, eLength);
	final eb = (_isEVR) ? new EvrLong(bd) : new Ivr(bd);
  final e = makePixelData(eb, vrIndex, fragments);
	_currentDS.elements.add(e);
  assert(_checkRIndex());
  return e;
}

// Temp Placeholder
Element makePixelData(EBytes ebd, int vrIndex, VFFragments fragments) {}
