// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

typedef Element<V> Maker<K, V>(K id, List<V> values,
    [int vfLength, VFFragments fragments]);

Dataset currentBDS;
Dataset currentTDS;
int nElements = 0;

TagRootDataset convertBDDSToTagDS(BDRootDataset rootBDS) {
  log.level = Level.warn1;
  currentBDS = rootBDS;
  final rootTDS = new TagRootDataset();
  currentTDS = rootTDS;

//  log.debug('tRoot.isRoot: ${rootTDS.isRoot}');
//  print('rootBDS Summary: ${rootBDS.summary}');
  print('duplicates: ${rootBDS.dupTotal}');
  convertRootDataset(rootBDS, rootTDS);
  print('rootTDS Summary: ${rootTDS.summary}');

  // Fix: can't compare datasets because Elements values are unprocessed
  // Uint8List.
  // if (rootBDS != rootTDS) log.error('**** rootBDS != rootTDS');
  if (rootBDS.total != rootTDS.total || rootBDS.dupTotal != rootTDS.dupTotal)
    _error(0, '**** rootBDS != rootTDS');
  log.info0('Exceptions: ${exceptions()}');
  return rootTDS;
}

Dataset convertRootDataset(RootDataset bdDS, RootDataset tagDS) {
  currentBDS = bdDS;
  currentTDS = tagDS;

  convertElements(bdDS.fmi, tagDS.fmi);
  convertElements(bdDS.elements, tagDS.elements);
  return tagDS;
}

void convertElements(ElementList bdElements, ElementList tagElements) {
  print('tagElements: $tagElements');
  if (tagElements.isNotEmpty) throw 'bad tagElements: $tagElements';
  for (var e in bdElements) {
//    print('convert: $e');
    final te = convertElement(e);
    tagElements.add(te);
    if (te == null) throw 'null TE';
  }
}

Map<String, Element> pcElements = <String, Element>{};

Element convertElement(Element be) {
//  print('be: $be');
  _warnVRIndex(be);

  final te = (be is SQ) ? convertSQ(be) : TagElement.fromBD(be, be.vrIndex);
//  print('te: $te');

  if (be.code != te.code)
    _error(be.code, 'Elements codes not equal: ${be.code}, ${te.code}');

  print('$te v:${valuesPrefix(te, 5)}');
  nElements++;
  return te;
}

const int kDefaultCount = 5;
//
String valuesPrefix(Element te, [int count = kDefaultCount]) {
  final length = te.values.length;
  if (length <= 0) return '[]';
  final sb = new StringBuffer('[');
  final limit = (length > count) ? count : length;
  final last = limit - 1;
  for (var i = 0; i < last; i++)
    sb.write('${te.values.elementAt(i)}, ');
  final end = (limit < length) ? '...]' : ']';
  sb.write('${te.values.elementAt(last)}$end');
  return sb.toString();
}

SQ convertSQ(SQ sq) {
  final tItems = new List<TagItem>(sq.items.length);
  final parentBDS = currentBDS;
  final parentTDS = currentTDS;
  for (var i = 0; i < sq.items.length; i++) {
    currentBDS = sq.items.elementAt(i);
    currentTDS = new TagItem(parentTDS, currentBDS.dsBytes.bd);
    convertItem(currentBDS, currentTDS);
    tItems[i] = currentTDS;
  }
  currentBDS = parentBDS;
  currentTDS = parentTDS;
  final tagSQ = new SQtag(sq.tag, parentTDS, tItems, sq.length);

  for (var item in tItems) item.add(tagSQ);
  return tagSQ;
}

void convertItem(Dataset beDS, Dataset tagDS) {
  final bdElements = beDS.elements;
  final tagElements = tagDS.elements;
  for (var e in bdElements) {
    print('convert: $e');
    final te = convertElement(e);
    if (te == null) throw 'null TE';
    tagElements.add(e);
  }
}

final Map<int, PCTag> pcTags = <int, PCTag>{};

// TODO: integrate this into /dictionary/tag
int _pcCodeFromPDCode(int pdCode) {
  final group = Group.fromTag(pdCode);
  final elt = Elt.fromTag(pdCode);
  final cElt = elt >> 8;
  final pcCode = (group << 16) + cElt;
  return pcCode;
}

List<String> _exceptions = <String>[];
String exceptions() => _exceptions.join('\n');

void _warnVRIndex(Element be) {
  final vrIndex = be.vrIndex;
  final tag = be.tag;
  if (vrIndex == be.tag.vrIndex) return;
  print('* vrIndex: $vrIndex tag.vrIndex: ${tag.vrIndex} $tag');

  _warn(be.code, 'be.vr(${be.vrId}) is NOT ${tag.vrIndex}');
  if (vrIndex == kUNIndex && isNormalVRIndex(tag.vrIndex)) {
    _warn(be.code, 'e.vr of ${be.vrId} was NOT changed to ${tag.vr.id}');
    //  vrIndex = tag.vrIndex;
  }
  if (isSpecialVRIndex(vrIndex)) _error(be.code, 'Non-Normal VR: $vrIndex');

  if (isSpecialVRIndex(tag.vrIndex)) {
    if (!vrByIndex[tag.vrIndex].isValidIndex(vrIndex))
      _warn(be.code, 'Invalid VR Index ($vrIndex) for $tag');
  }
}

void _warn(int code, String msg) {
  final s = '** Warning ${dcm(code)} $msg';
  _exceptions.add(s);
  log.warn(s);
}

void _error(int code, String msg) {
  final s = '\n**** Error: ${dcm(code)} $msg';
  _exceptions.add(s);
  log.error(s);
}

