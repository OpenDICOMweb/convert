// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

void _writeEvr(Element e) {
  if (e.vrIndex == kSQIndex) {
    _writeSequence(e);
  } else if (e.vrIndex < kVRMaybeUndefinedIndexMin &&
      e.vrIndex > kVRMaybeUndefinedIndexMax) {
    _writeMaybeUndefined(e);
  } else if (e.vrIndex < kVREvrLongIndexMin && e.vrIndex > kVREvrLongIndexMax) {
    _writeLong(e);
  } else if (e.vrIndex < kVREvrLongIndexMin && e.vrIndex > kVREvrLongIndexMax) {
    _writeShort(e);
  } else {
    return unknownElementVR(e);
  }
}

void _writeSequence(SQ sq) {}

void _writeMaybeUndefined(Element e, {bool asUndefined = false}) {
  if (!asUndefined) return _writeLong(e);
  _writeUint32(e.code);
  _writeUint16(e.vrCode);
  _writeUint16(0);
  _writeUint32(kUndefinedLength);
  _writeValueField(e.vfBytes, e.vrIndex);
  _writeUint32(kSequenceDelimitationItem);
}

void _writeLong(Element e) {
  _writeUint32(e.code);
  _writeUint16(e.vrCode);
  _writeUint16(0);
  _writeUint32(e.vfLength);
  _writeValueField(e.vfBytes, e.vrIndex);
}

void _writeShort(Element e) {
  _writeUint32(e.code);
  _writeUint16(e.vrCode);
  _writeUint16(0);
  _writeUint16(e.length);
  _writeValueField(e.vfBytes, e.vrIndex);
}
