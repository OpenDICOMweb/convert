// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart' hide Indenter;

typedef Element ValueFieldReader(Tag tag, int vrIndex, List vf);

Element readValueField(int code, int vrIndex, dynamic vf) {
  final tag = Tag.lookupByCode(code, vrIndex);
  return _readers[vrIndex](tag, vrIndex, vf);
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


Null _sqError(int code, int vrIndex, List vf) => invalidElementIndex(vrIndex);

OBtag _readOB(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kOBIndex);
  return OBtag.make<int>(tag, BASE64.decode(vf).buffer.asUint8List());
}

OWtag _readOW(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kOWIndex);
  return OWtag.make<int>(tag, BASE64.decode(vf).buffer.asUint16List());
}

UNtag _readUN(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kUNIndex);
  return UNtag.make<int>(tag, BASE64.decode(vf).buffer.asUint8List());
}

OLtag _readOL(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kOLIndex);
  return OLtag.make<int>(tag, BASE64.decode(vf).buffer.asUint32List());
}

OFtag _readOF(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kOFIndex);
  return OFtag.make<double>(tag, BASE64.decode(vf).buffer.asFloat32List());
}

ODtag _readOD(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kODIndex);
  return ODtag.make<double>(tag, BASE64.decode(vf).buffer.asFloat64List());
}

SStag _readSS(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kSSIndex);
  if (vf is List<int>) return SStag.make<int>(tag, vf);
  return invalidValueField('', vf);
}

SLtag _readSL(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kSLIndex);
  if (vf is List<int>) return SLtag.make<int>(tag, vf);
}

ATtag _readAT(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kATIndex);
  if (vf is List<int>) return ATtag.make<int>(tag, vf);
}

UStag _readUS(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kUSIndex);
  if (vf is List<int>) return UStag.make<int>(tag, vf);
}

ULtag _readUL(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kULIndex);
  if (vf is List<int>) return ULtag.make<int>(tag, vf);
}

FLtag _readFL(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kFLIndex);
  if (vf is List<double>) return FLtag.make<double>(tag, vf);
}

FDtag _readFD(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kFDIndex);
  if (vf is List<double>) return FDtag.make<double>(tag, vf);

}


AEtag _readAE(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kAEIndex);
  if (vf is List<String>) return AEtag.make<double>(tag, vf);

}

CStag _readCS(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kCSIndex && tag.vrIndex == kCSIndex);
  if (vf is List<String>)  return CStag.make(tag, vf);
}

SHtag _readSH(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kSHIndex && tag.vrIndex == kSHIndex);
  if (vf is List<String>)  return SHtag.make(tag, vf);
}

LOtag _readLO(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kLOIndex && tag.vrIndex == kLOIndex);
  if (vf is List<String>) return LOtag.make<String>(tag, vf);
}

UCtag _readUC(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kUCIndex && tag.vrIndex == kUCIndex);
  if (vf is List<String>) return UCtag.make(tag, vf);
}

STtag _readST(Tag tag, int vrIndex, List vf) {
  if (vf is List<String>) {
    assert(vrIndex == kSTIndex && tag.vrIndex == kSTIndex);
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return STtag.make(tag, vf);
  }
  return invalidValueField();
}

LTtag _readLT(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kLTIndex && tag.vrIndex == kLTIndex);
  if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
  if (vf is List<String>)  return LTtag.make(tag, vf);
}

UTtag _readUT(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kUTIndex && tag.vrIndex == kUTIndex);
  if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
  if (vf is List<String>) return UTtag.make(tag, vf);
}

URtag _readUR(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kURIndex && tag.vrIndex == kURIndex);
  if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
  if (vf is List<String>) return URtag.make(tag, vf);
}

AStag _readAS(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kASIndex);
  if (vf.length > 1 || vf[0].length != 4)
    log.error('Invalid AS Value Field: $vf');
  if (vf is List<String>)  return AStag.make(tag, vf);
}

DAtag _readDA(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kDAIndex && tag.vrIndex == kDAIndex);
  if (vf is List<String>)  return DAtag.make(tag, vf);
}

DTtag _readDT(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kDTIndex && tag.vrIndex == kDTIndex);
  if (vf is List<String>) return DTtag.make(tag, vf);
}

TMtag _readTM(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kTMIndex && tag.vrIndex == kTMIndex);
  if (vf is List<String>) return TMtag.make(tag, vf);
}

IStag _readIS(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kISIndex && tag.vrIndex == kISIndex);
  if (vf is List<String>) return IStag.make(tag, vf);
}

DStag _readDS(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kDSIndex && tag.vrIndex == kDSIndex);
  if (vf is List<String>) return DStag.make(tag, vf);
}

UItag _readUI(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kUIIndex && tag.vrIndex == kUIIndex);
  if (vf is List<String>) return UItag.make(tag, vf);
}

PNtag _readPN(Tag tag, int vrIndex, List vf) {
  assert(vrIndex == kPNIndex && tag.vrIndex == kPNIndex);
  if (vf is List<String>) return PNtag.make(tag, vf);
}
