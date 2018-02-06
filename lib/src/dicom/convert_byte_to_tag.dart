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

TagRootDataset convertByteDSToTagDS(BDRootDataset rootBDS) {
  log.level = Level.warn1;
  currentBDS = rootBDS;
  final rootTDS = new TagRootDataset.from(rootBDS);
  log.debug('tRoot.isRoot: ${rootTDS.isRoot}');

  convertDataset(rootBDS, rootTDS);

  print('rootBDS Summary: ${rootBDS.summary}');
  print('rootTDS Summary: ${rootTDS.summary}');
  // Fix: can't compare datasets because Elements values are unprocessed
  // Uint8List.
  // if (rootBDS != rootTDS) log.error('**** rootBDS != rootTDS');
  if (rootBDS.total != rootTDS.total || rootBDS.dupTotal != rootTDS.dupTotal)
    _error(0, '**** rootBDS != rootTDS');
  log.info0('Exceptions: ${exceptions()}');
  return rootTDS;
}

Dataset convertDataset(Dataset byteDS, Dataset tagDS) {
  currentBDS = byteDS;
  currentTDS = tagDS;
  for (var e in byteDS.elements) {
    print('convert: $e');
    final te = convertElement(e);
    if (te == null) throw 'null TE';
  }
  for (var e in byteDS.elements.duplicates) {
    final te = convertElement(e);
    if (te == null) throw 'null TE';
  }
  return tagDS;
}

Map<String, Element> pcElements = <String, Element>{};

Element convertElement(Element be) {
  log.level = Level.info;

  int vrIndex;
  final tag = be.tag;
  if (be.vrIndex == tag.vrIndex) {
    vrIndex = be.vrIndex;
  } else {
    _warn(be.code, 'be.vr (${be.vrId}) is NOT $tag');
    if (be.vrIndex == kUNIndex && isNormalVRIndex(tag.vrIndex)) {
      _warn(be.code, 'e.vr of ${be.vrId} was NOT changed to ${tag.vr.id}');
    //  vrIndex = tag.vrIndex;
    }
    if (isSpecialVRIndex(be.vrIndex))
      _error(be.code, 'Non-Normal VR: ${be.vrIndex}');

    if (isSpecialVRIndex(tag.vrIndex)) {
      if (!vrByIndex[tag.vrIndex].isValidIndex(be.vrIndex))
        _warn(be.code, 'Invalid VR Index (${be.vrIndex} for $tag');
      vrIndex = be.vrIndex;
    }
  }

  if (vrIndex == kLOIndex) print('vrIndex = $vrIndex $be');

  Element te;
  if (be is SQ) {
    te = convertSQ(be);
  } else if (tag is PCTagUnknown) {
    te = TagElement.from(be, be.vrIndex);
    log.info0('PCTagUnknown\n  $be\n  $te');
  } else if (be.code == kPixelData) {
    te = TagElement.from(be, vrIndex);
    log.info0('PixelData\n  $be\n  $te');
  } else if (be is PrivateCreator) {
    if (be.vrIndex != kLOIndex)
      _warn(be.code, 'Private Creator e.vr(${be.vrId}) should be VR.kLO');
    assert(tag is PCTag && tag.name == be.asString);
    te = TagElement.from(be, vrIndex);
    pcElements[be.asString] = te;
  } else if (tag is PDTag) {
    te = TagElement.from(be, vrIndex);
  } else if (be is BDElement) {
    te = TagElement.from(be, vrIndex);
  } else {
    throw 'Invalid Tag: $tag';
  }
  if (be.code != te.code)
    _error(be.code, 'Elements codes not equal: ${be.code}, ${te.code}');
/*
  log.info('BE: ${be.info}');
  log.info('BE Values: ${be.values}');
  log.info('TE: ${te.info}');
  log.info('TE Values: ${te.values}');*/

  currentTDS.add(te);
  nElements++;
  return te;
}

SQ convertSQ(SQ sq) {
  final tItems = new List<TagItem>(sq.items.length);
  final parentBDS = currentBDS;
  final parentTDS = currentTDS;
  for (var i = 0; i < sq.items.length; i++) {
    currentBDS = sq.items.elementAt(i);
    currentTDS = new TagItem(parentTDS, currentBDS.dsBytes.bd);
    tItems[i] = convertDataset(currentBDS, currentTDS);
  }
  currentBDS = parentBDS;
  currentTDS = parentTDS;
  final tagSQ = new SQtag(sq.tag, currentTDS, tItems, sq.length);

  for (var item in tItems) item.add(tagSQ);
  return tagSQ;
}

final Map<int, PCTag> pcTags = <int, PCTag>{};

Tag getTag(Element be) {
  final code = be.code;
  final vrIndex = be.vrIndex;
  Tag tag;
  if (Tag.isPublicCode(code)) {
    tag = PTag.lookupByCode(code, vrIndex);
  } else if (Tag.isPrivateCreatorCode(code)) {
    final name = be.asString;
    if (be.vrIndex != kLOIndex)
      _warn(be.code, 'Creator $name with vr($vrIndex) != VR.kLO: $be');
    log.debug2('   Creator: $name');
    tag = new PCTag(code, vrIndex, name);
    pcTags[code] = tag;
  } else if (Tag.isPrivateDataCode(code)) {
    final creatorCode = pcCodeFromPDCode(code);
    final creator = pcTags[creatorCode];
    tag = new PDTag(code, vrIndex, creator);
  } else {
    throw 'couldn\'t get tag: ${be.info}';
  }
  log.debug2('Tag: $tag');
  return tag;
}

// TODO: integrate this into /dictionary/tag
int pcCodeFromPDCode(int pdCode) {
  final group = Group.fromTag(pdCode);
  final elt = Elt.fromTag(pdCode);
  final cElt = elt >> 8;
  final pcCode = (group << 16) + cElt;
  return pcCode;
}

List<String> _exceptions = <String>[];

String exceptions() => _exceptions.join('\n');
void _warn(int code, String msg) {
  final s = '**   Warning ${dcm(code)}  $msg';
  _exceptions.add(s);
  log.warn(s);
}

void _error(int code, String msg) {
  final s = '\n**** Error: ${dcm(code)} $msg';
  _exceptions.add(s);
  log.error(s);
}
