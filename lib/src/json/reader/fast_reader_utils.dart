// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

typedef Element ValueFieldReader(Tag tag, int vrIndex, List vf);

Element readValueField(int code, int vrIndex, List values) {
  final tag = Tag.lookupByCode(code, vrIndex);
  return _readers[vrIndex](tag, vrIndex, values);
}

const List<ValueFieldReader> _readers = const <ValueFieldReader>[
  // Begin maybe undefined length
  _readSQ, // Sequence == 0,
  // Begin EVR Long
  _readOB, _readOW, _readUN,
  // End maybe Undefined Length
  // EVR Long
  _readOD, _readOF, _readOL, _readUC, _readUR, _readUT,
  // End Evr Long
  // Begin EVR Short
  _readAE, _readAS, _readAT, _readCS, _readDA, _readDS, _readDT,
  _readFD, _readFL, _readIS, _readLO, _readLT, _readPN, _readSH,
  _readSL, _readSS, _readST, _readTM, _readUI, _readUL, _readUS,
];

Null _readSQ(Tag tag, int vrIndex, Iterable vf) => invalidElementIndex(vrIndex);

OBtag _readOB(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOBIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OBtag.make(tag, BASE64.decode(value).buffer.asUint8List());

  if (key == 'BulkDataURI')
    return OBtag.make(tag, new IntBulkdata(tag.code, value));

  return invalidValuesError(vf);
}

OWtag _readOW(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOWIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OWtag.make(tag, BASE64.decode(value).buffer.asUint8List());

  if (key == 'BulkDataURI')
    return OWtag.make(tag, new IntBulkdata(tag.code, value));

  return invalidValuesError(vf);
}

UNtag _readUN(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUNIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return UNtag.make(tag, BASE64.decode(value).buffer.asUint8List());

  if (key == 'BulkDataURI')
    return UNtag.make(tag, new IntBulkdata(tag.code, value));

  return invalidValuesError(vf);
}

OLtag _readOL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOLIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OLtag.make(tag, BASE64.decode(value).buffer.asUint8List());

  if (key == 'BulkDataURI')
    return OLtag.make(tag, new IntBulkdata(tag.code, value));

  return invalidValuesError(vf);
}

OFtag _readOF(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOFIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OFtag.fromBytes(tag, BASE64.decode(value).buffer.asUint8List());

  if (key == 'BulkDataURI')
    return OFtag.make(tag, new FloatBulkdata(tag.code, value));

  return invalidValuesError(vf);
}

ODtag _readOD(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kODIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return ODtag.fromBytes(tag, BASE64.decode(value).buffer.asUint8List());

  if (key == 'BulkDataURI')
    return ODtag.make(tag, new FloatBulkdata(tag.code, value));

  return invalidValuesError(vf);
}

IntBulkdata _getIntBulkdata(Tag tag, Iterable vf) {
  assert(vf.isNotEmpty);
  final Object key = vf.elementAt(0);
  return (key is String && key == 'BulkDataURI')
      ? new IntBulkdata(tag.code, vf.elementAt(1))
      : null;
}

StringBulkdata _getStringBulkdata(Tag tag, Iterable vf) {
  assert(vf.isNotEmpty);
  final Object key = vf.elementAt(0);
  return (key is String && key == 'BulkDataURI')
      ? new StringBulkdata(tag.code, vf.elementAt(1))
      : null;
}

SStag _readSS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kSSIndex);
  if (vf is List<int>) return SStag.make(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? SStag.make(tag, bulkdata)
      : invalidValueField('', vf);
}

SLtag _readSL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kSLIndex);
  if (vf is List<int>) return SLtag.make(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? SLtag.make(tag, bulkdata)
      : invalidValueField('', vf);
}

ATtag _readAT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kATIndex);
  return (vf is List<int>)
      ? ATtag.make(tag, vf)
      : invalidValueField('', vf);
}

UStag _readUS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUSIndex);
  if (vf is List<int>) return UStag.make(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? UStag.make(tag, bulkdata)
      : invalidValueField('', vf);
}

ULtag _readUL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kULIndex);
  if (vf is List<int>) return ULtag.make(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? ULtag.make(tag, bulkdata)
      : invalidValueField('', vf);
}

FloatBulkdata _getFloatBulkdata(Tag tag, Iterable vf) {
  assert(vf.isNotEmpty);
  final Object key = vf.elementAt(0);
  return (key is String && key == 'BulkDataURI')
      ? new FloatBulkdata(tag.code, vf.elementAt(1))
      : null;
}

FLtag _readFL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kFLIndex);
  if (vf is List<double>) return FLtag.make(tag, vf);

  final bulkdata = _getFloatBulkdata(tag, vf);
  return (bulkdata != null)
      ? FLtag.make(tag, bulkdata)
      : invalidValueField('', vf);
}

FDtag _readFD(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kFDIndex);
  if (vf is List<double>) return FDtag.make(tag, vf);

  final bulkdata = _getFloatBulkdata(tag, vf);
  return (bulkdata != null)
      ? FDtag.make(tag, bulkdata)
      : invalidValueField('', vf);
}

AEtag _readAE(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kAEIndex);
  return (vf is List<String>)
      ? AEtag.make(tag, vf)
      : invalidValueField('', vf);
}

CStag _readCS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kCSIndex && tag.vrIndex == kCSIndex);
  if (vf is List<String>) return CStag.make(tag, vf);
  assert(vf is List<String>);
  return CStag.make(tag, vf);
}

SHtag _readSH(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kSHIndex && tag.vrIndex == kSHIndex);
  if (vf is List<String>) return SHtag.make(tag, vf);
  assert(vf is List<String>);
  return SHtag.make(tag, vf);
}

LOtag _readLO(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kLOIndex && tag.vrIndex == kLOIndex);
  if (vf is List<String>) return LOtag.make(tag, vf);
  assert(vf is List<String>);
  return LOtag.make(tag, vf);
}

UCtag _readUC(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUCIndex && tag.vrIndex == kUCIndex);
  if (vf is List<String>) return UCtag.make(tag, vf);
  assert(vf is List<String>);
  return UCtag.make(tag, vf);
}

STtag _readST(Tag tag, int vrIndex, Iterable vf) {
  if (vf is List<String>) {
    assert(vrIndex == kSTIndex && tag.vrIndex == kSTIndex);
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return STtag.make(tag, vf);
  }
  return invalidValuesError(vf);
}

LTtag _readLT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kLTIndex && tag.vrIndex == kLTIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return LTtag.make(tag, vf);
  }
  assert(vf is List<String>);
  return LTtag.make(tag, vf);
}

UTtag _readUT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUTIndex && tag.vrIndex == kUTIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
  } else {
    log.error('Invalid AS Value Field: $vf');
  }
  return UTtag.make(tag, vf);
}

URtag _readUR(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kURIndex && tag.vrIndex == kURIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return URtag.make(tag, vf);
  }
  return URtag.make(tag, vf);
}

AStag _readAS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kASIndex);
  if (vf is List<String>) {
    if (vf.length > 1 || vf[0].length != 4)
      log.error('Invalid AS Value Field: $vf');
    return AStag.make(tag, vf);
  }
  return AStag.make(tag, vf);
}

DAtag _readDA(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kDAIndex && tag.vrIndex == kDAIndex);
  if (vf is List<String>) return DAtag.make(tag, vf);
  assert(vf is List<String>);
  return DAtag.make(tag, vf);
}

DTtag _readDT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kDTIndex && tag.vrIndex == kDTIndex);
  if (vf is List<String>) return DTtag.make(tag, vf);
  assert(vf is List<String>);
  return DTtag.make(tag, vf);
}

TMtag _readTM(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kTMIndex && tag.vrIndex == kTMIndex);
  if (vf is List<String>) return TMtag.make(tag, vf);
  assert(vf is List<String>);
  return TMtag.make(tag, vf);
}

IStag _readIS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kISIndex && tag.vrIndex == kISIndex);
  if (vf is List<String>) return IStag.make(tag, vf);
  assert(vf is List<String>);
  return IStag.make(tag, vf);
}

DStag _readDS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kDSIndex && tag.vrIndex == kDSIndex);
  if (vf is List<String>) return DStag.make(tag, vf);
  assert(vf is List<String>);
  return DStag.make(tag, vf);
}

UItag _readUI(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUIIndex && tag.vrIndex == kUIIndex);
  if (vf is List<String>) return UItag.make(tag, vf);
  assert(vf is List<String>);
  return UItag.make(tag, vf);
}

PNtag _readPN(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kPNIndex && tag.vrIndex == kPNIndex);
  if (vf is List<String>) return PNtag.make(tag, vf);
  assert(vf is List<String>);
  return PNtag.make(tag, vf);
}
