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

TagRootDataset convertByteDSToTagDS<V>(BDRootDataset rootBDS) {
  log.level = Level.warn1;
  currentBDS = rootBDS;
  final rootTDS = new TagRootDataset.from(rootBDS);
  log.debug('tRoot.isRoot: ${rootTDS.isRoot}');

  convertDataset(rootBDS, rootTDS);

  // Fix: can't compare datasets because Elements values are unprocessed
  // Uint8List.
  // if (rootBDS != rootTDS) log.error('**** rootBDS != rootTDS');
  if (rootBDS.total != rootTDS.total || rootBDS.dupTotal != rootTDS.dupTotal)
    _error(0, '**** rootBDS != rootTDS');
  log.info0(_exceptions);
  return rootTDS;
}

Dataset convertDataset(Dataset byteDS, Dataset tagDS) {
  currentBDS = byteDS;
  currentTDS = tagDS;
  for (var e in byteDS.elements) {
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

//Urgent fix
Element convertElement(Element be) {
  log.level = Level.info;
  var vrCode = be.vrCode;

  final tag = be.tag;
  if (be.vrIndex == kUNIndex && tag.vr != VR.kUN)
    _warn(be.code, 'e.vr of ${be.vrId} was changed to ${tag.vr}');
  if (tag.vr == VR.kUN && be.vrIndex != kUNIndex) {
    //Fix: this needs to do better with tags that have multiple VRs
    vrCode = be.vrCode;
    _warn(be.code, 'VR of $tag was changed to ${be.vrId}');
  }

  Element te;
  if (be is SQ) {
    te = convertSQ(be);
  } else if (be.code == kPixelData) {
    te = TagElement.from(be);
    log.info0('PixelData\n  $be\n  $te');
  } else if (be is BDElement) {
    te = TagElement.from(be);
  } else if (be is PrivateCreator) {
    if (be.vrIndex != kLOIndex)
      _warn(be.code, 'Private Creator e.vr(${be.vrId}) should be VR.kLO');
    if (vrCode != VR.kLO.code) throw 'Invalid Tag VR: ${tag.vr} should be VR.kLO';
    assert(tag is PCTag && tag.name == be.asString);
    te = TagElement.from(be);
    pcElements[be.asString] = te;
  } else if (tag is PDTag) {
    te = TagElement.from(be);
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
    tag = new PCTag(code, kLOIndex, name);
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

void _warn(int code, String msg) {
  final s = '**   Warning ${dcm(code)}  $msg';
  _exceptions.add(s);
  log.warn(s);
}

void _error(int code, String msg) {
  final s = '**** Error: ${dcm(code)} $msg';
  _exceptions.add(s);
  log.error(s);
}
