//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

// ignore_for_file: only_throw_errors

/*
typedef Element<V> _Maker<K, V>(K id, List<V> values,
    [int vfLength, VFFragments fragments]);
*/

RootDataset sourceRDS;
RootDataset targetRDS;
Dataset currentSDS;
Dataset currentTDS;
int nElements = 0;
List<String> _exceptions = <String>[];

/// Converts any [RootDataset] to a [TagRootDataset]
TagRootDataset convertToTagDataset(RootDataset sourceRDS,
    {bool keepFmi = true}) {
  log.level = Level.warn1;
  // rootBds = sourceRds;
  currentSDS = sourceRDS;
  targetRDS = new TagRootDataset.empty();
  currentTDS = targetRDS;

  log
    ..debug('sourceRDS: ${sourceRDS.total} elements')
    ..debug('    ${sourceRDS.summary}')
    ..debug('Convert FMI');
  nElements = 0;
  if (keepFmi) _convertFmi(sourceRDS, targetRDS);

  log.debug('Convert Root Dataset');
  nElements = 0;
  _convertRootDataset(sourceRDS, targetRDS);

  log
    ..debug('   Summary: ${targetRDS.summary}')
    ..debug('     Count: $nElements')
    ..debug('Exceptions: ${_exceptions.join('\n')}');
  return targetRDS;
}

void _convertFmi(RootDataset sRDS, RootDataset tRDS) {
  log
    ..debug('  count: $nElements')
    ..debug('  rootBDS FMI: ${sRDS.fmi.length}')
    ..debug('  rootTDS FMI: ${tRDS.fmi.length}');
  if (targetRDS.fmi.isNotEmpty) throw 'bad targetRDS: $tRDS';
  for (var e in sRDS.fmi.elements) {
    final te = convertElement(e);
    tRDS.fmi[te.code] = te;
    if (te == null) throw 'null TE';
  }
  log.debug('  count: $nElements');
}

void _convertRootDataset(RootDataset sRds, RootDataset tRDS) {
  log.debug('  count: $nElements');
  if (tRDS.isNotEmpty) throw 'bad rootTds: $tRDS';
  for (var e in sRds.elements) {
    final te = convertElement(e);
    tRDS.add(te);
    if (te == null) throw 'null TE';
  }
}

Map<String, Element> pcElements = <String, Element>{};

Element convertElement(Element e) {
  _warnVRIndex(e);
  final te = (e is SQ) ? convertSQ(e) : _convertSimpleElement(e);
  if (e.code != te.code)
    _error(e.code, 'Elements codes not equal: ${e.code}, ${te.code}');
  nElements++;
  return te;
}

Element _convertSimpleElement(Element e) {
  if (e.vrIndex > 30) throw 'bad e.vr: ${e.vrIndex}';
  return  TagElement.makeFromValues(e.code, e.vrIndex, e.values, sourceRDS);
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
  // Current source Dataset
  final parentSDS = currentSDS;
  // Current target Dataset
  final parentTDS = currentTDS;
  for (var i = 0; i < sq.items.length; i++) {
    currentSDS = sq.items.elementAt(i);
    currentTDS = new TagItem.empty(parentTDS, sq);
    convertItem(currentSDS, currentTDS);
    tItems[i] = currentTDS;
  }
  currentSDS = parentSDS;
  currentTDS = parentTDS;
  final tagSQ = new SQtag(parentTDS, sq.tag,  tItems);

  for (var item in tItems) item.sequence = tagSQ;
  return tagSQ;
}

void convertItem(Item sourceItem, Item targetItem) {
  //var _currentGroup = 0;
 // var _currentSubgroup = 0;
//  Element _currentCreator;
//  String _currentCreatorToken;
  for (var e in sourceItem.elements) {
//    final gNumber = e.group;

//    log.debug('convert: $e');
    final te = convertElement(e);
    if (te == null) throw 'null TE';
    targetItem.add(te);
  }
}

final Map<int, PCTag> pcTags = <int, PCTag>{};

/*
// TODO: integrate this into /dictionary/tag
int _pcCodeFromPDCode(int pdCode) {
  final group = Tag.toGroup(pdCode);
  final elt = Tag.toElt(pdCode);
  final cElt = elt >> 8;
  final pcCode = (group << 16) + cElt;
  return pcCode;
}
*/

void _warnVRIndex(Element e) {
  final vrIndex = e.vrIndex;
  final tag = e.tag;
  if (vrIndex == e.tag.vrIndex) return;
  _warn(e.code, 'e.vr(${e.vrId}) is NOT ${tag.vrIndex}');
  if (vrIndex == kUNIndex && isNormalVRIndex(tag.vrIndex))
    _warn(e.code, 'e.vr of ${e.vrId} was NOT changed to ${tag.vr.id}');

  if (isSpecialVRIndex(vrIndex)) _error(e.code, 'Non-Normal VR: $vrIndex');

  final targetVR = tag.vrIndex;
  if (isSpecialVRIndex(targetVR)) {
    if (!VR.isValidIndex(targetVR, null, vrIndex))
      _warn(e.code, 'Invalid VR Index ($vrIndex) for $tag');
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
