// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:dictionary/dictionary.dart';
import 'package:core/core.dart';

Logger log = new Logger('convert', watermark: Severity.info);

typedef Element<I, V> Maker<I, V>(I id, List<V> values,
    [int vfLength, VFFragments fragments]);

RootTDataset convertByteToTag(RootByteDataset source) {
  RootTDataset result = new RootTDataset.fromByteData(
      bd: source.bd,
      path: source.path,
      vfLength: source.vfLength,
      hadUndefinedLength: source.hadULength);

  Iterable<ByteElement> elements = source.elements;
  for (ByteElement e in elements) {
    TElement te = convertElement(result, e);
    if (te == null) throw 'null TE';
    result.add(te);
  }
  return result;
}

Map<String, TElement> pcElements = <String, TElement>{};

TElement convertElement(TDataset result, ByteElement e) {
  if (e is ByteSQ) return getSequence(result, e);
  log.debug1(' BE: $e');
  var tag = getTag(e);
  VR vr = e.vr;
  if (e.vr == VR.kUN && tag.vr != VR.kUN) {
    VR oldVR = e.vr;
    VR vr0 = tag.vr;
    log.warn('e.vr of $oldVR was changed to ${tag.vr}');
  }

  TElement te;
  if (tag is PTag) {
    if (tag.code == kPixelData) {
      log.info('**** Byte Element Pixel Data ${e.info}');
      if (e is BytePixelData) {
        if (e.isEncapsulated) {
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
      Maker maker = TElement.makers[vr.index];
      te = maker(tag, e.vfBytes, e.vfLength);
    }
  } else if (tag is PCTag) {
    if (e.vr != VR.kLO)
      log.warn('Private Creator e.vr(${e.vr}) should be VR.kLO');
    if (tag.vr != VR.kLO) throw 'Invalid Tag VR: ${tag.vr} should be VR.kLO';
    Maker maker = TElement.makers[vr.index];
    te = maker(tag, e.vfBytes, e.vfLength);
    assert(tag is PCTag && tag.name == e.asString);
    pcElements[e.asString] = te;
  } else if (tag is PDTag) {
    Maker maker = TElement.makers[vr.index];
    te = maker(tag, e.vfBytes, e.vfLength);
  } else {
    throw 'Invalid Tag: $tag';
  }
  log.debug(' TE: $te');
  return te;
}

SQ getSequence(TDataset result, ByteSQ sq) {
  Tag tag = getTag(sq);
//    var elements = source.elements;
  List<TItem> tItems = new List<TItem>(sq.items.length);
  for (int i = 0; i < sq.items.length; i++) {
    var bItem = sq.items[i];
    Map<int, TElement> tMap = <int, TElement>{};
    for (ByteElement e in bItem.elements) {
      TElement te = convertElement(result, e);
      tMap[te.code] = te;
    }
    tItems[i] = new TItem(result, tMap, bItem.vfLength);
  }
  return new SQ(tag, tItems, sq.vfLength);
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
