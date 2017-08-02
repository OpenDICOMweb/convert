// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

Logger log = new Logger('convert', Level.info);

typedef Element<K, V> Maker<K, V>(K id, List<V> values,
    [int vfLength, VFFragments fragments]);

ByteDataset currentBDS;
TagDataset currentTDS;
bool isEVR;
int nElements = 0;

RootTagDataset convertByteDSToTagDS(RootByteDataset rootBDS) {
  currentBDS = rootBDS;
  isEVR = rootBDS.isEVR;
  RootTagDataset rootTDS = new RootTagDataset.fromByteData(rootBDS.bd);
  log.debug('tRoot.isRoot: ${rootTDS.isRoot}');

  convertDataset(rootBDS, rootTDS);
  print('Total Elements: $nElements');
  return rootTDS;
}

TagDataset convertDataset(ByteDataset byteDS, TagDataset tagDS) {
  currentBDS = byteDS;
  isEVR = byteDS.isEVR;
//  log.debug('tRoot.isRoot: ${tagDS.isRoot}');
  currentTDS = tagDS;
  for (ByteElement e in byteDS.elements) {
    TagElement te = convertElement(e);
    if (te == null) throw 'null TE';
  }
  for (ByteElement e in byteDS.duplicates) {
    TagElement te = convertElement(e);
    if (te == null) throw 'null TE';
  }
  print('Dataset Elements: $nElements');
  return tagDS;
}

Map<String, TagElement> pcElements = <String, TagElement>{};

//Urgent fix
TagElement convertElement(ByteElement be) {
  log.debug1(' BE: $be');
  var code = be.code;
  var vrCode = be.vrCode;

  var tag = getTag(be);
  if (be.vr == VR.kUN && tag.vr != VR.kUN)
    log.warn('e.vr of ${be.vr} was changed to ${tag.vr}');
  if (tag.vr == VR.kUN && be.vr != VR.kUN) {
    vrCode = be.vrCode;
    log.warn('VR of $tag was changed to ${be.vr}');
  }

  TagElement te;
  if (be is ByteSQ) {
    te = convertSQ(be);
  } else if (tag is PTag) {
    if (tag.code == kPixelData) {
      BytePixelData pd;
      pd = be;
      te = TagElement.makeElementFromBytes(
          code, vrCode, pd.vfLength, pd.vfBytes, pd.fragments);
      log.info('PixelData $pd, $te');
    } else {
      te = TagElement.makeElementFromBytes(
          code, vrCode, be.vfLength, be.vfBytes);
    }
  } else if (tag is PCTag) {
    if (be.vr != VR.kLO)
      log.warn('Private Creator e.vr(${be.vr}) should be VR.kLO');
    if (vrCode != VR.kLO.code)
      throw 'Invalid Tag VR: ${tag.vr} should be VR.kLO';
    te = TagElement.makeElementFromBytes(code, vrCode, be.vfLength, be.vfBytes);
    assert(tag is PCTag && tag.name == be.asString);
    pcElements[be.asString] = te;
  } else if (tag is PDTag) {
    te = TagElement.makeElementFromBytes(code, vrCode, be.vfLength, be.vfBytes);
  } else {
    throw 'Invalid Tag: $tag';
  }
  log.debug(' TE: $te');
  currentTDS.add(te);
  nElements++;
  return te;
}

SQ convertSQ(ByteSQ byteSQ) {
  Tag tag = getTag(byteSQ);
  var tItems = new List<TagItem>(byteSQ.items.length);
  var parentBDS = currentBDS;
  var parentTDS = currentTDS;
  for (int i = 0; i < byteSQ.items.length; i++) {
    currentBDS = byteSQ.items[i];
    print('item: $currentBDS');
    currentTDS = new TagItem.fromDecoder(currentBDS.bd, parentTDS,
        currentBDS.vfLength, <int, TagElement>{}, <int, TagElement>{});
    tItems[i] = convertDataset(currentBDS, currentTDS);
    print('item[$i] $currentTDS');
  }
  currentBDS = parentBDS;
  currentTDS = parentTDS;
  var tagSQ = new SQ(tag, tItems, byteSQ.vfLength);

  print('byteSQ: ${byteSQ.info}');
  print('tagSQ: ${tagSQ.info}');
  for (TagItem item in tItems) item.addSQ(tagSQ);
  print('convertSQ: nElements: $nElements');
  return tagSQ;
}

final Map<int, PCTag> pcTags = <int, PCTag>{};

Tag getTag(ByteElement e) {
  int code = e.code;
  VR vr = e.vr;
  Tag tag;
  if (Tag.isPublicCode(code)) {
    tag = PTag.lookupCode(code, vr);
  } else if (Tag.isPrivateCreatorCode(code)) {
    var name = e.asString;
    if (e.vr != VR.kLO) log.warn('   Creator $name with vr($vr) != VR.kLO: $e');
    log.debug2('   Creator: $name');
    tag = new PCTag(code, VR.kLO, name);
    pcTags[code] = tag;
  } else if (Tag.isPrivateDataCode(code)) {
    int creatorCode = pcCodeFromPDCode(code);
    PCTag creator = pcTags[creatorCode];
    tag = new PDTag(code, vr, creator);
  } else {
    throw 'couldn\'t get tag: ${e.info}';
  }
  log.debug1('Tag: $tag');
  return tag;
}

// TODO: integrate this int /dictionary/tag
int pcCodeFromPDCode(int pdCode) {
  int group = Group.fromTag(pdCode);
  int elt = Elt.fromTag(pdCode);
  int cElt = elt >> 8;
  int pcCode = (group << 16) + cElt;
  return pcCode;
}
