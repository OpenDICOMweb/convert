// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

void _readIvrRootDataset() => __readRootDataset(_readIvrElement);

/// All [Element]s are read by this method.
Element _readIvrElement() {
  _elementCount++;
  final eStart = _rb.rIndex;
  final code = _rb.code;
  final tag = __checkCode(code, eStart);
  final vrIndex = __lookupIvrVRIndex(code, eStart, tag);

  log.debug('${_rb.rbb} #$_elementCount readIvr ${dcm(code)} VR($vrIndex) @$eStart', 1);

  Element e;
  if (_isIvrDefinedLengthVR(vrIndex)) {
    e = _readIvrDefinedLength(code, eStart, vrIndex);
    log.up;
  } else if (vrIndex == kVRIndexMin) {
    e = _readIvrSQ(code, eStart);
    log.up;
  } else if (_isMaybeUndefinedLengthVR(vrIndex)) {
    e = _readIvrMaybeUndefinedLength(code, eStart, vrIndex);
    log.up;
  } else {
    return invalidVRIndexError(vrIndex);
  }

  // Elements are always read into the current dataset.
  // **** This is the only place they are added to the dataset.
  final ok = _cds.tryAdd(e);
  if (!ok) log.warn('*** duplicate: $e');

  if (_statisticsEnabled) _doEndOfElementStats(code, eStart, e, ok);
  log.debug('${_rb.ree} readIvr $e', -1);
  return e;
}

int __lookupIvrVRIndex(int code, int eStart, Tag tag) {
  final vr = (tag == null) ? VR.kUN : tag.vr;
  return __vrToIndex(code, vr);
}

/// Read an IVR Element (not SQ) with a 32-bit vfLengthField (vlf),
/// but that cannot have kUndefinedValue.
Element _readIvrDefinedLength(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint32;
  assert(vlf != kUndefinedLength);
  return __readDefinedLength(code, eStart, vrIndex, vlf, Ivr.make);
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element _readIvrMaybeUndefinedLength(int code, int eStart, int vrIndex) {
  final vlf = _rb.uint32;
  return __readMaybeUndefinedLength(
      code, eStart, vrIndex, vlf, Ivr.make, _readIvrElement);
}

Element _readIvrSQ(int code, int eStart) {
  final vlf = _rb.uint32;
  return __readSQ(code, eStart, vlf, Ivr.make, _readIvrElement);
}

