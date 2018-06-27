//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

typedef Element _ValueFieldReader(Tag tag, int vrIndex, List vf);

Element readValueField(Tag tag, int vrIndex, Object vf) {
  dynamic values;
  if (vf is Uri) {
    values = new IntBulkdataRef(tag.code, vf);
  } else if (vrIndex >= kOBIndex && vrIndex <= kODIndex) {
    values = base64.decode(vf).buffer.asUint8List();
  } else if (vf is List) {
    values = vf;
  }
  return _readers[vrIndex](tag, vrIndex, values);
}

const List<_ValueFieldReader> _readers = const <_ValueFieldReader>[
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

OBtag _readOB(Tag tag, int vrIndex, Object vf) {
  assert(vrIndex == kOBIndex);
  dynamic values;
  if (vf is String) {
    values = base64.decode(vf).buffer.asUint8List();
  } else if (vf is Uri) {
    values = new IntBulkdataRef(tag.code, vf);
  } else if (vf is List) {
    values = vf;
  } else {
    return badValues(vf);
  }
  return OBtag.fromValues(tag, values);
}

OWtag _readOW(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOWIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OWtag.fromBytes(tag, Bytes.fromBase64(value));

  if (key == 'BulkDataURI') {
    final uri = new Uri.dataFromString(value);
    return new OWtag(tag, new IntBulkdataRef(tag.code, uri));
  }

  return badValues(vf);
}

UNtag _readUN(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUNIndex);
  dynamic values;
  if (vf.isEmpty) {
    values = kEmptyUint8List;
  } else {
    final String key = vf.elementAt(0);
    final String value = vf.elementAt(1);
    if (key == 'InlineBinary') {
      values = Bytes.fromBase64(value);
    } else if (key == 'BulkDataURI') {
      final uri = new Uri.dataFromString(value);
      values = new IntBulkdataRef(tag.code, uri);
    } else {
      return badValues(vf);
    }
  }
  return UNtag.fromValues(tag, values);
}

OLtag _readOL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOLIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OLtag.fromBytes(tag, Bytes.fromBase64(value));
  if (key == 'BulkDataURI') {
    final bd = new FloatBulkdataRef(tag.code, Uri.parse(value));
    return OLtag.bulkdata(tag, bd.uri);
  }
  return badValues(vf);
}

OFtag _readOF(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kOFIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return OFtag.fromBytes(tag, Bytes.fromBase64(value));

  if (key == 'BulkDataURI')
    return OFtag.fromValues(
        tag, new FloatBulkdataRef(tag.code, Uri.parse(value)));

  return badValues(vf);
}

ODtag _readOD(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kODIndex);
  final String key = vf.elementAt(0);
  final String value = vf.elementAt(1);
  if (key == 'InlineBinary')
    return ODtag.fromBytes(tag, Bytes.fromBase64(value));
  if (key == 'BulkDataURI')
    return ODtag.fromValues(
        tag, new FloatBulkdataRef(tag.code, Uri.parse(value)));
  return badValues(vf);
}

IntBulkdataRef _getIntBulkdata(Tag tag, Iterable vf) {
  assert(vf.isNotEmpty);
  final Object key = vf.elementAt(0);
  return (key is String && key == 'BulkDataURI')
      ? new IntBulkdataRef(tag.code, vf.elementAt(1))
      : null;
}

/*
StringBulkdata _getStringBulkdata(Tag tag, Iterable vf) {
  assert(vf.isNotEmpty);
  final Object key = vf.elementAt(0);
  return (key is String && key == 'BulkDataURI')
      ? new StringBulkdata(tag.code, vf.elementAt(1))
      : null;
}
*/

SStag _readSS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kSSIndex);
  if (vf is List<int>) return SStag.fromValues(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? new SStag.bulkdata(tag, bulkdata.uri)
      : invalidValueField('', vf);
}

SLtag _readSL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kSLIndex);
  if (vf is List<int>) return SLtag.fromValues(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? SLtag.fromValues(tag, bulkdata)
      : invalidValueField('', vf);
}

ATtag _readAT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kATIndex);
  return (vf is List<int>)
      ? ATtag.fromValues(tag, vf)
      : invalidValueField('', vf);
}

UStag _readUS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUSIndex);
  if (vf is List<int>) return UStag.fromValues(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? UStag.fromValues(tag, bulkdata)
      : invalidValueField('', vf);
}

ULtag _readUL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kULIndex);
  if (vf is List<int>) return ULtag.fromValues(tag, vf);

  final bulkdata = _getIntBulkdata(tag, vf);
  return (bulkdata != null)
      ? ULtag.fromValues(tag, bulkdata)
      : invalidValueField('', vf);
}

FloatBulkdataRef _getFloatBulkdata(Tag tag, Iterable vf) {
  assert(vf.isNotEmpty);
  final Object key = vf.elementAt(0);
  return (key is String && key == 'BulkDataURI')
      ? new FloatBulkdataRef(tag.code, vf.elementAt(1))
      : null;
}

FLtag _readFL(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kFLIndex);
  if (vf is List<double>) return FLtag.fromValues(tag, vf);

  final bulkdata = _getFloatBulkdata(tag, vf);
  return (bulkdata != null)
      ? FLtag.fromValues(tag, bulkdata)
      : invalidValueField('', vf);
}

FDtag _readFD(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kFDIndex);
  if (vf is List<double>) return FDtag.fromValues(tag, vf);

  final bulkdata = _getFloatBulkdata(tag, vf);
  return (bulkdata != null)
      ? FDtag.fromValues(tag, bulkdata)
      : invalidValueField('', vf);
}

AEtag _readAE(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kAEIndex);
  return (vf is List<String>)
      ? AEtag.fromValues(tag, vf)
      : invalidValueField('', vf);
}

CStag _readCS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kCSIndex && tag.vrIndex == kCSIndex);
  if (vf is List<String>) return CStag.fromValues(tag, vf);
  assert(vf is List<String>);
  return CStag.fromValues(tag, vf);
}

SHtag _readSH(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kSHIndex && tag.vrIndex == kSHIndex);
  if (vf is List<String>) return SHtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return SHtag.fromValues(tag, vf);
}

LOtag _readLO(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kLOIndex && tag.vrIndex == kLOIndex);
  if (vf is List<String>) return LOtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return LOtag.fromValues(tag, vf);
}

UCtag _readUC(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUCIndex && tag.vrIndex == kUCIndex);
  if (vf is List<String>) return UCtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return UCtag.fromValues(tag, vf);
}

STtag _readST(Tag tag, int vrIndex, Iterable vf) {
  if (vf is List<String>) {
    assert(vrIndex == kSTIndex && tag.vrIndex == kSTIndex);
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return new STtag(tag, vf);
  }
  return badValues(vf);
}

LTtag _readLT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kLTIndex && tag.vrIndex == kLTIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return new LTtag(tag, vf);
  }
  assert(vf is List<String>);
  return LTtag.fromValues(tag, vf);
}

UTtag _readUT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUTIndex && tag.vrIndex == kUTIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
  } else {
    log.error('Invalid AS Value Field: $vf');
  }
  return UTtag.fromValues(tag, vf);
}

URtag _readUR(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kURIndex && tag.vrIndex == kURIndex);
  if (vf is List<String>) {
    if (vf.length > 1) log.error('Invalid AS Value Field: $vf');
    return URtag.fromValues(tag, vf);
  }
  return URtag.fromValues(tag, vf);
}

AStag _readAS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kASIndex);
  if (vf is List<String>) {
    if (vf.length > 1 || vf[0].length != 4)
      log.error('Invalid AS Value Field: $vf');
    return AStag.fromValues(tag, vf);
  }
  return AStag.fromValues(tag, vf);
}

DAtag _readDA(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kDAIndex && tag.vrIndex == kDAIndex);
  if (vf is List<String>) return DAtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return DAtag.fromValues(tag, vf);
}

DTtag _readDT(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kDTIndex && tag.vrIndex == kDTIndex);
  if (vf is List<String>) return DTtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return DTtag.fromValues(tag, vf);
}

TMtag _readTM(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kTMIndex && tag.vrIndex == kTMIndex);
  if (vf is List<String>) return TMtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return TMtag.fromValues(tag, vf);
}

IStag _readIS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kISIndex && tag.vrIndex == kISIndex);
  if (vf is List<String>) return IStag.fromValues(tag, vf);
  assert(vf is List<String>);
  return IStag.fromValues(tag, vf);
}

DStag _readDS(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kDSIndex && tag.vrIndex == kDSIndex);
  if (vf is List<String>) return DStag.fromValues(tag, vf);
  assert(vf is List<String>);
  return DStag.fromValues(tag, vf);
}

UItag _readUI(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kUIIndex && tag.vrIndex == kUIIndex);
  if (vf is List<String>) return UItag.fromValues(tag, vf);
  assert(vf is List<String>);
  return UItag.fromValues(tag, vf);
}

PNtag _readPN(Tag tag, int vrIndex, Iterable vf) {
  assert(vrIndex == kPNIndex && tag.vrIndex == kPNIndex);
  if (vf is List<String>) return PNtag.fromValues(tag, vf);
  assert(vf is List<String>);
  return PNtag.fromValues(tag, vf);
}
