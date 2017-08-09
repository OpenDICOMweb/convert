// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:core/byte_dataset.dart';
import 'package:core/tag_dataset.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/src/dcm/byte_reader.dart';

typedef Element<K, V> Maker<K, V>(K id, List<V> values,
    [int vfLength, VFFragments fragments]);

ByteDataset currentBDS;
TagDataset currentTDS;
bool isEVR;
int nElements = 0;

RootTagDataset convertByteDSToTagDS(RootByteDataset rootBDS) {
  Logger log = new Logger('convertByteDSToTagDS', Level.info);

  log.level = Level.warn1;
  currentBDS = rootBDS;
  isEVR = rootBDS.isEVR;
  RootTagDataset rootTDS = new RootTagDataset.fromByteData(rootBDS.bd);
  log.debug('tRoot.isRoot: ${rootTDS.isRoot}');

  convertDataset(rootBDS, rootTDS);

  // Fix: can't compare datasets because ByteElements values are unprocessed
  // Uint8List.
  // if (rootBDS != rootTDS) log.error('**** rootBDS != rootTDS');
  if (rootBDS.total != rootTDS.total ||
      rootBDS.dupTotal != rootTDS.dupTotal)
    _error(0, '**** rootBDS != rootTDS');
  log.info0(exceptions);
  return rootTDS;
}

TagDataset convertDataset(ByteDataset byteDS, TagDataset tagDS) {
  currentBDS = byteDS;
  isEVR = byteDS.isEVR;
  currentTDS = tagDS;
  for (ByteElement e in byteDS.elements) {
    TagElement te = convertElement(e);
    if (te == null) throw 'null TE';
  }
  for (ByteElement e in byteDS.duplicates) {
    TagElement te = convertElement(e);
    if (te == null) throw 'null TE';
  }
  return tagDS;
}

Map<String, TagElement> pcElements = <String, TagElement>{};

//Urgent fix
TagElement convertElement(ByteElement be) {
  Logger log = new Logger('convertElement', Level.info);
  log.level = Level.info;
  var code = be.code;
  var vrCode = be.vrCode;

  var tag = getTag(be);
  if (be.vr == VR.kUN && tag.vr != VR.kUN)
    _warn(be.code, 'e.vr of ${be.vr} was changed to ${tag.vr}');
  if (tag.vr == VR.kUN && be.vr != VR.kUN) {
    //Fix: this needs to do better with tags that have multiple VRs
    vrCode = be.vrCode;
    _warn(be.code, 'VR of $tag was changed to ${be.vr}');
  }

  TagElement te;
  if (be.isSequence) {
    te = convertSQ(be);
  } else if (tag is PTag) {
    if (tag.code == kPixelData) {
      te = ByteReader.makeTagPixelData(be);
      log.info('PixelData\n  $be\n  $te');
    } else {
      te = be.tagElementFromBytes;
    }
  } else if (tag is PCTag) {
    if (be.vr != VR.kLO)
      _warn(be.code, 'Private Creator e.vr(${be.vr}) should be VR.kLO');
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

SQ convertSQ(Element e) {
  assert(e.isSequence);
  SequenceMixin sq = e as SequenceMixin;
  var tItems = new List<TagItem>(sq.items.length);
  var parentBDS = currentBDS;
  var parentTDS = currentTDS;
  for (int i = 0; i < sq.items.length; i++) {
    currentBDS = sq.items[i];
//    print('item: $currentBDS');
    currentTDS = new TagItem.fromDecoder(currentBDS.bd, parentTDS,
        currentBDS.vfLength, <int, TagElement>{}, <int, TagElement>{});
    tItems[i] = convertDataset(currentBDS, currentTDS);
//    print('item[$i] $currentTDS');
  }
  currentBDS = parentBDS;
  currentTDS = parentTDS;
  var tagSQ = new SQ(sq.tag, currentTDS, tItems, sq.vfLength);

//  print('byteSQ: ${byteSQ.info}');
//  print('tagSQ: ${tagSQ.info}');
  for (TagItem item in tItems) item.addSQ(tagSQ);
//  print('convertSQ: nElements: $nElements');
  return tagSQ;
}

final Map<int, PCTag> pcTags = <int, PCTag>{};

Tag getTag(ByteElement be) {
  int code = be.code;
  VR vr = be.vr;
  Tag tag;
  if (Tag.isPublicCode(code)) {
    tag = PTag.lookupByCode(code, vr);
  } else if (Tag.isPrivateCreatorCode(code)) {
    var name = be.asString;
    if (be.vr != VR.kLO)
      _warn(be.code, 'Creator $name with vr($vr) != VR.kLO: $be');
    log.debug2('   Creator: $name');
    tag = new PCTag(code, VR.kLO, name);
    pcTags[code] = tag;
  } else if (Tag.isPrivateDataCode(code)) {
    int creatorCode = pcCodeFromPDCode(code);
    PCTag creator = pcTags[creatorCode];
    tag = new PDTag(code, vr, creator);
  } else {
    throw 'couldn\'t get tag: ${be.info}';
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

List<String> exceptions = <String>[];

void _warn(int code, String msg)  {
  var s = '**   Warning ${toDcm(code)}  $msg';
  exceptions.add(s);
  log.warn(s);
}

void _error(int code, String msg)  {
  var s = '**** Error: ${toDcm(code)} $msg';
  exceptions.add(s);
  log.error(s);
}
