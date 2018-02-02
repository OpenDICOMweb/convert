// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

typedef Element ValueFieldReader(Tag tag, int vrIndex, Object vf);

Element readValueField(int code, int vrIndex, Object values) {
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

Null _readSQ(Tag tag, int vrIndex, Object vf) => invalidElementIndex(vrIndex);

OBtag _readOB(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kOBIndex);
  return (vf is String)
      ? OBtag.make<int>(tag, BASE64.decode(vf).buffer.asUint8List())
      : invalidValuesError(vf);
}

OWtag _readOW(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kOWIndex);
  return (vf is String)
      ? OWtag.make<int>(tag, BASE64.decode(vf).buffer.asUint16List())
      : invalidValuesError(vf);
}

UNtag _readUN(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kUNIndex);
  return (vf is String)
      ? UNtag.make<int>(tag, BASE64.decode(vf).buffer.asUint8List())
      : invalidValuesError(vf);
}

OLtag _readOL(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kOLIndex);
  return (vf is String)
      ? OLtag.make<int>(tag, BASE64.decode(vf).buffer.asUint32List())
      : invalidValuesError(vf);
}

OFtag _readOF(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kOFIndex);
  return (vf is String)
      ? OFtag.make<double>(tag, BASE64.decode(vf).buffer.asFloat32List())
      : invalidValuesError(vf);
}

ODtag _readOD(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kODIndex);
  return (vf is String)
      ? ODtag.make<double>(tag, BASE64.decode(vf).buffer.asFloat64List())
      : invalidValuesError(vf);
}

SStag _readSS(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kSSIndex);
  return (vf is List<int>)
  ? SStag.make<int>(tag, vf)
  : invalidValueField('', vf);
}

SLtag _readSL(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kSLIndex);
  return (vf is List<int>)
  ? SLtag.make<int>(tag, vf)
      :    invalidValueField('', vf);
}

ATtag _readAT(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kATIndex);
  return (vf is List<int>)
  ? ATtag.make<int>(tag, vf)
  :    invalidValueField('', vf);
}

UStag _readUS(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kUSIndex);
  return (vf is List<int>)
  ? UStag.make<int>(tag, vf)
  : invalidValueField('', vf);
}

ULtag _readUL(Tag tag, int vrIndex, List values) {
  assert(vrIndex == kULIndex);
  return (values is List<int>)
      ? ULtag.make<int>(tag, values)
      : invalidValueField('', values);
}

FLtag _readFL(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kFLIndex);
  return (vf is List<double>)
  ? FLtag.make<double>(tag, vf)
      : invalidValueField('', vf);
}

FDtag _readFD(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kFDIndex);
  return (vf is List<double>) ? FDtag.make<double>(tag, vf)
  : invalidValueField('', vf);
}

AEtag _readAE(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kAEIndex);
  return (vf is List<String>) ? AEtag.make<String>(tag, vf)
  : invalidValueField('', vf);
}

CStag _readCS(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kCSIndex && tag.vrIndex == kCSIndex);
  if (vf is List<String>)
    return CStag.make(tag, vf);
  assert(vf is List<String>);
  return CStag.make<String>(tag, vf);
}

SHtag _readSH(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kSHIndex && tag.vrIndex == kSHIndex);
  if (vf is List<String>) return SHtag.make(tag, vf);
  assert(vf is List<String>);
  return SHtag.make<String>(tag, vf);
}

LOtag _readLO(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kLOIndex && tag.vrIndex == kLOIndex);
  if (vf is List<String>) return LOtag.make<String>(tag, vf);
  assert(vf is List<String>);
  return LOtag.make<String>(tag, vf);
}

UCtag _readUC(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kUCIndex && tag.vrIndex == kUCIndex);
  if (vf is List<String>) return UCtag.make(tag, vf);
  assert(vf is List<String>);
  return UCtag.make<String>(tag, vf);
}

STtag _readST(Tag tag, int vrIndex, Object vf) {
  if (vf is List<String>) {
    assert(vrIndex == kSTIndex && tag.vrIndex == kSTIndex);
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return STtag.make(tag, vf);
  }
  return invalidValuesError(vf);
}

LTtag _readLT(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kLTIndex && tag.vrIndex == kLTIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
     return LTtag.make(tag, vf);
  }
  assert(vf is List<String>);
  return LTtag.make<String>(tag, vf);
}

UTtag _readUT(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kUTIndex && tag.vrIndex == kUTIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
  } else {
    log.error('Invalid AS Value Field: $vf');
  }
  return UTtag.make<String>(tag, vf);
}

URtag _readUR(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kURIndex && tag.vrIndex == kURIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return URtag.make(tag, vf);
  }
  return URtag.make<String>(tag, vf);
}

AStag _readAS(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kASIndex);
  if (vf is List<String>) {
    if (vf.length > 1 || vf[0].length != 4)
      log.error('Invalid AS Value Field: $vf');
    return AStag.make(tag, vf);
  }
  return AStag.make<String>(tag, vf);
}

DAtag _readDA(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kDAIndex && tag.vrIndex == kDAIndex);
  if (vf is List<String>) return DAtag.make(tag, vf);
  assert(vf is List<String>);
  return DAtag.make<String>(tag, vf);
}

DTtag _readDT(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kDTIndex && tag.vrIndex == kDTIndex);
  if (vf is List<String>) return DTtag.make(tag, vf);
  assert(vf is List<String>);
  return DTtag.make<String>(tag, vf);
}

TMtag _readTM(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kTMIndex && tag.vrIndex == kTMIndex);
  if (vf is List<String>) return TMtag.make(tag, vf);
  assert(vf is List<String>);
  return TMtag.make<String>(tag, vf);
}

IStag _readIS(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kISIndex && tag.vrIndex == kISIndex);
  if (vf is List<String>) return IStag.make(tag, vf);
  assert(vf is List<String>);
  return IStag.make<String>(tag, vf);
}

DStag _readDS(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kDSIndex && tag.vrIndex == kDSIndex);
  if (vf is List<String>) return DStag.make(tag, vf);
  assert(vf is List<String>);
  return DStag.make<String>(tag, vf);
}

UItag _readUI(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kUIIndex && tag.vrIndex == kUIIndex);
  if (vf is List<String>) return UItag.make(tag, vf);
  assert(vf is List<String>);
  return UItag.make<String>(tag, vf);
}

PNtag _readPN(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kPNIndex && tag.vrIndex == kPNIndex);
  if (vf is List<String>) return PNtag.make(tag, vf);
  assert(vf is List<String>);
  return PNtag.make<String>(tag, vf);
}
