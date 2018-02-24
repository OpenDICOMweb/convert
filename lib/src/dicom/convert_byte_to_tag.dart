// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

typedef Element<V> Maker<K, V>(K id, List<V> values,
    [int vfLength, VFFragments fragments]);

RootDataset rootBds;
RootDataset rootTds;
Dataset currentBds;
Dataset currentTds;
int nElements = 0;
List<String> _exceptions = <String>[];

TagRootDataset convertBDDSToTagDS(RootDataset root) {
  log.level = Level.warn1;
  rootBds = root;
  currentBds = rootBds;
  rootTds = new TagRootDataset.empty();
  currentTds = rootTds;

  log
    ..debug('rootBDS: ${rootBds.total} elements')
    ..debug('rootBDS: ${rootBds.summary}')
    ..debug('Convert FMI');
  nElements = 0;
  _convertFmi(rootBds, rootTds);

  log.debug('Convert Root Dataset');
  nElements = 0;
  _convertRootDataset(rootBds, rootTds);

  log
    ..debug('   Summary: ${rootTds.summary}')
    ..debug('     Count: $nElements')
    ..debug('Exceptions: ${_exceptions.join('\n')}');
  return rootTds;
}

void _convertFmi(RootDataset rootBds, RootDataset rootTagDS) {
  log
    ..debug('  count: $nElements')
    ..debug('  rootBDS FMI: ${rootBds.fmi.length}')
    ..debug('  rootTDS FMI: ${rootTagDS.fmi.length}');
  if (rootTds.fmi.isNotEmpty) throw 'bad rootTagDS: $rootTagDS';
  for (var e in rootBds.fmi.elements) {
    final te = convertElement(e);
    rootTagDS.fmi[te.code] = te;
    if (te == null) throw 'null TE';
  }
  log.debug('  count: $nElements');
}

void _convertRootDataset(RootDataset rootBds, RootDataset rootTds) {
  log.debug('  count: $nElements');
  if (rootTds.isNotEmpty) throw 'bad rootTds: $rootTds';
  for (var e in rootBds.elements) {
    final te = convertElement(e);
    rootTds.add(te);
    if (te == null) throw 'null TE';
  }
}

Map<String, Element> pcElements = <String, Element>{};

Element convertElement(Element be) {
//  log.debug('be: $be');
  _warnVRIndex(be);

  final te = (be is SQ) ? convertSQ(be) : _convertSimpleElement(be);
//  log.debug('te: $te');

  if (be.code != te.code)
    _error(be.code, 'Elements codes not equal: ${be.code}, ${te.code}');

//  log.debug('$te v:${valuesPrefix(te, 5)}');
  nElements++;
  return te;
}

Element _convertSimpleElement(Element e) {
//  log.debug('be.vrIndex: ${e.vrIndex}');
  if (e.vrIndex > 30) throw 'bad be.vr: ${e.vrIndex}';
  final tag = Tag.lookupByCode(e.code, e.vrIndex);
  return (e.tag == PTag.kPixelData)
      ? TagElement.pixelDataFromBDE(e, rootBds.transferSyntax, e.vrIndex)
      : TagElement.from(e, e.vrIndex);
}

Element _convertMaybeUndefinedElement(Element e) {
//  log.debug('be.vrIndex: ${e.vrIndex}');
//  if (e.vrIndex)
  if (e.vrIndex > 30) throw 'bad be.vr: ${e.vrIndex}';
  return (e.tag == PTag.kPixelData)
      ? TagElement.pixelDataFromBDE(e, rootBds.transferSyntax, e.vrIndex)
      : TagElement.fromBDE(e, e.vrIndex);
}

const int kDefaultCount = 5;

String valuesPrefix(Element te, [int count = kDefaultCount]) {
  final length = te.values.length;
  if (length <= 0) return '[]';
  final sb = new StringBuffer('[');
  final limit = (length > count) ? count : length;
  final last = limit - 1;
  for (var i = 0; i < last; i++) sb.write('${te.values.elementAt(i)}, ');
  final end = (limit < length) ? '...]' : ']';
  sb.write('${te.values.elementAt(last)}$end');
  return sb.toString();
}

SQ convertSQ(SQ sq) {
  final tItems = new List<TagItem>(sq.items.length);
  final parentBDS = currentBds;
  final parentTDS = currentTds;
  for (var i = 0; i < sq.items.length; i++) {
    currentBds = sq.items.elementAt(i);
    currentTds = new TagItem.empty(parentTDS, sq, currentBds.dsBytes.bd);
    convertItem(currentBds, currentTds);
    tItems[i] = currentTds;
  }
  currentBds = parentBDS;
  currentTds = parentTDS;
  final tagSQ = new SQtag(sq.tag, parentTDS, tItems, sq.length);

  for (var item in tItems) item.sequence = tagSQ;
  return tagSQ;
}

void convertItem(Item bdItem, Item tagItem) {
  var _currentGroup = 0;
  var _currentSubgroup = 0;
  Element _currentCreator;
  String _currentCreatorToken;
  for (var e in bdItem.elements) {
    final gNumber = e.group;

//    log.debug('convert: $e');
    final te = convertElement(e);
    if (te == null) throw 'null TE';
    tagItem.add(te);
  }
}

final Map<int, PCTag> pcTags = <int, PCTag>{};

// TODO: integrate this into /dictionary/tag
int _pcCodeFromPDCode(int pdCode) {
  final group = Tag.toGroup(pdCode);
  final elt = Tag.toElt(pdCode);
  final cElt = elt >> 8;
  final pcCode = (group << 16) + cElt;
  return pcCode;
}

void _warnVRIndex(Element be) {
  final vrIndex = be.vrIndex;
  final tag = be.tag;
  if (vrIndex == be.tag.vrIndex) return;
//  log.debug('* vrIndex: $vrIndex tag.vrIndex: ${tag.vrIndex} $tag');

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
