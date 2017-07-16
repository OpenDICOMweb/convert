// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

Logger log = new Logger('convert', watermark: Severity.info);

typedef Element<K, T, V> Maker<K, T, V>(K id, List<V> values,
    [int vfLength, VFFragments fragments]);

ByteDataset currentBDS;
TagDataset currentTDS;
bool isEVR;

RootTagDataset convertByteDSToTagDS(RootByteDataset rootBDS) {
  currentBDS = rootBDS;
  isEVR = rootBDS.isEVR;
  RootTagDataset rootTDS = new RootTagDataset.fromByteData(rootBDS.bd);

  Iterable<Element> elements = rootBDS.elements;
  for (ByteElement e in elements) {
    TagElement te = convertElement(rootTDS, e);
    if (te == null) throw 'null TE';
    rootTDS.add(te);
  }
  return rootTDS;
}

Map<String, TagElement> pcElements = <String, TagElement>{};

TagElement convertElement(TagDataset result, ByteElement e) {
  if (e is ByteSQ) return getSequence(result, e);
  log.debug1(' BE: $e');
  var code = e.code;
  var vrCode = e.vrCode;
  var tag = getTag(e);

  if (e.vr == VR.kUN && tag.vr != VR.kUN)
    log.warn('e.vr of ${e.vr} was changed to ${tag.vr}');
  TagElement te;
  if (tag is PTag) {
    if (tag.code == kPixelData) {
      log.info('**** Byte Element Pixel Data ${e.info}');
      if (e is BytePixelData) {
        //
        if (e.isEncapsulated) {
          if (e.vrCode == VR.kUN.code)
            log.warn('Pixel Data vr(${e.vr} -> VR.kOB');
          log.info('**** OB Pixel Data ${e.info}');
          log.info('**** OB Fragments ${e.fragments.info}');
          te = OB.parseBytes(tag, e.vfBytes, e.vfLength, e.fragments);
        } else {
          if (e.vr == VR.kUN) log.warn('Pixel Data vr(${e.vr} -> VR.kOW');
          te = OW.parseBytes(tag, e.vfBytes, e.vfLength);
        }
      } else {
        throw 'Invalid Pixel Data VR: ${e.info}';
      }
      log.info('**** Tag Pixel Data ${te.info}');
    } else {
      te = TagElement.makeElementFromBytes(code, vrCode, e.vfBytes, e.vfLength);
    }
  } else if (tag is PCTag) {
    if (e.vr != VR.kLO)
      log.warn('Private Creator e.vr(${e.vr}) should be VR.kLO');
    if (vrCode != VR.kLO.code)
      throw 'Invalid Tag VR: ${tag.vr} should be VR.kLO';
    te = TagElement.makeElementFromBytes(code, vrCode, e.vfBytes, e.vfLength);
    assert(tag is PCTag && tag.name == e.asString);
    pcElements[e.asString] = te;
  } else if (tag is PDTag) {
    te = TagElement.makeElementFromBytes(code, vrCode, e.vfBytes, e.vfLength);
  } else {
    throw 'Invalid Tag: $tag';
  }
  log.debug(' TE: $te');
  return te;
}

SQ getSequence(TagDataset result, ByteSQ sq) {
  Tag tag = getTag(sq);
  var tItems = new List<TagItem>(sq.items.length);
  var parentBDS = currentBDS;
  var parentTDS = currentTDS;
  for (int i = 0; i < sq.items.length; i++) {
    ByteDataset currentBDS = sq.items[i];
    var currentTDS = new TagItem(
        parentTDS, currentBDS.vfLength, currentBDS.hadULength, currentBDS.bd);
    for (ByteElement e in currentBDS.elements) {
      TagElement te = convertElement(result, e);
      currentTDS.add(te);
    }
    tItems[i] = currentTDS;
  }
  currentBDS = parentBDS;
  currentTDS = parentTDS;
  return new SQ(tag, tItems, sq.vfLength, sq.hadULength);
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
