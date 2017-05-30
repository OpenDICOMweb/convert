// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:dictionary/dictionary.dart';
import 'package:core/core.dart';

Logger log = new Logger('convert', watermark: Severity.debug2);

typedef Element<V> Maker<I, V>(I id, List<V> values, [int vfLength]);

class DSConverter {
  final RootByteDataset sourceRoot;
  final RootTDataset resultRoot;
  ByteDataset sourceDS;
  TDataset resultDS;
  PCTag creator;

  DSConverter(this.sourceRoot)
      : resultRoot = new RootTDataset(
      path: sourceRoot.path,
      hadUndefinedLength: sourceRoot.hadUndefinedLength) {
    sourceDS = sourceRoot;
    resultDS = resultRoot;
  }

  TDataset run() {
    Iterable<ByteElement> elements = sourceDS.elements;
    for (ByteElement e in elements) {
      Element te = convertElement(e);
      if (te == null) throw 'null TE';
      resultDS[te.code] = te;
    }
    var s0 = new Summary(sourceDS);
    var s1 = new Summary(resultDS);
    log.info('$s0');
    log.info('$s1');
    return resultDS;
  }


  // TODO: integrate this int /dictionary/tag
  int pcCodeFromPDCode(int pdCode) {
    int group = Group.fromTag(pdCode);
//    print('group(${Uint16.hex(group)})');
    int elt = Elt.fromTag(pdCode);
//    print('Elt(${Uint16.hex(elt)})');
    int cElt = elt >> 8;
//    print('cElt(${Uint16.hex(cElt)})');
    int pcCode = (group << 16) + cElt;
//    print('pdCode(${Tag.toHex(pdCode)}, pcCode(${Tag.toHex(pcCode)})');
    return pcCode;
  }

  Map<int, PCTag> pcTags = <int, PCTag>{};

  Tag getTag(ByteElement e) {
    int code = e.code;
    VR vr = e.vr;
    Tag tag;
    if (Tag.isPublicCode(code)) {
      tag = PTag.lookupCode(code, vr);
    } else if (Tag.isPrivateCreatorCode(code)) {
      var name = e.asString;
      if (e.vr != VR.kLO) log.warn('   Creator $name with vr != VR.kLO: $e');
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
    if (e.vr == VR.kUN) log.warn('   VR.kUN to ${tag.vr}');
    log.debug1('Tag: $tag');
    return tag;
  }


  Map<String, TElement> pcElements = <String, TElement>{};

  TElement convertElement(ByteElement e) {
    if (e is ByteSQ) return getSequence(e);
    log.debug1('  E: $e');
    var tag = getTag(e);
    VR vr0 = (e.vr == VR.kUN) ? tag.vr : e.vr;
    if (vr0 != tag.vr) log.warn(
        'e.vr($vr0) and tag.vr(${tag.vr}) are not equal');

    TElement te;
    if (tag is PTag) {
      Maker maker = TElement.makers[vr0.index];
      te = maker(tag, e.vfBytes, e.vfLength);
    } else if (tag is PCTag) {
      if (e.vr != VR.kLO) log.warn(
          'Private Creator e.vr($vr0) should be VR.kLO');
      if (tag.vr != VR.kLO)
        throw 'Invalid Tag VR: ${tag.vr} should be VR.kLO';
      Maker maker = TElement.makers[vr0.index];
      te = maker(tag, e.vfBytes, e.vfLength);
      assert(tag is PCTag && tag.name == e.asString);
      pcElements[e.asString] = te;
    } else if (tag is PDTag) {
      Maker maker = TElement.makers[vr0.index];
      te = maker(tag, e.vfBytes, e.vfLength);
    } else {
      throw 'Invalid Tag: $tag';
    }
    log.debug(' TE: $te');
    return te;
  }

  void privateGroup(ByteElement e) {

  }

  SQ getSequence(ByteSQ sq) {
    Tag tag = getTag(sq);
//    var elements = sourceDS.elements;
    List<TItem> tItems = new List<TItem>(sq.items.length);
    for (int i = 0; i < sq.items.length; i++) {
      var bItem = sq.items[i];
      Map<int, TElement> tMap = <int, TElement>{};
      for (ByteElement e in bItem.elements) {
        TElement te = convertElement(e);
        tMap[te.code] = te;
      }
      tItems[i] = new TItem(resultDS, tMap, bItem.vfLength);
    }
    return new SQ(tag, tItems, sq.vfLength);
  }

  void group(int group, ByteElement e) {
  }


/* Urgent: finish this Private Element Converter/Validator
  Dataset convertDataset(Dataset source, Dataset result) {
    Iterable<ByteElement> elements = sourceDS.elements;
    for (ByteElement e in elements) {
      int code = e.code;
      if (Tag.isPublicCode(e.code)) {
      Element te = convertElement(e);
      assert(te.tag is PCTag);
        log.debug2(te);
        if (te == null) throw 'null TE';
        print('te: $te');
        resultDS[te.code] = te;
      } else {
        int group = Group.fromTag(code);
        PrivateGroup pg = new PrivateGroup(group);
        do {
          int code = e.code;
          int elt = Elt.fromTag(code);
          Element te = convertElement(e);
          if (elt == 0) {
            // Group Length
          } else if (elt < 0x10) {
            // Illegal
            do {

            } while (elt < 0x10);
          } else if (elt < 0xFF) {
            // Creators
            do {

            } while (elt < 0xFF);
          } else if (elt > 0x0100 ) {
            // Data
            if (elt < 0x1000) {
              // Illegal Data
            }
            do {

            } while ()
          }

        }
      }
    }
  }

  /// Reads and returns a [PrivateGroup].
  ///
  /// A [PrivateGroup] contains all the  [PrivateCreator] and the corresponding
  /// [PrivateData] Data [TagElement]s with the same (private) group number.
  ///
  /// This method is called when the first Private Tag Code in a Private Group
  /// is encountered, and control remains in this group until the next
  /// Public Group is encountered.
  ///
  /// _Notes_:
  ///     1. All PrivateCreators are read before any of the [PrivateData]
  /// [TagElement]s are read.
  ///
  ///     2. PrivateCreators for one private group all occur before their
  /// corresponding Private Data TagElements.
  ///
  ///     3. It is possible to encounter a Private Data TagElement that does
  ///     not have a creator. This should be recorded in [Dataset].exceptions.
  ///
  /// Note: designed to read just one PrivateGroup and return it.
  PrivateGroup readPrivateGroup(int group, List<Element> sElements, int
  index) {
    Element be = sElements[index];
    assert(Group.isPrivate(be.group), "Non Private Group ${Tag.toHex(be.code)
    }");

    var pg = new PrivateGroup(group);
      resultDS.privateGroups.add(pg);

    // Private Group Lengths are retired but still might be present.
    if (be.elt == 0x0000) {
      var te = convertElement(be);
      resultDS.add(te);
      pg.gLength = te;
      index++;
      be = sElement[index];
    }
    // There should be no [Element]s with [Elt] numbers between 0x01 and 0x0F.
    // [Elt]s between 0x01 and 0x0F are illegal.
    if (be.elt < 0x0010) nextCode = toPIllegal(group, be, pg);

    // [Elt]s between 0x10 and 0xFF are [PrivateCreator]s.

    if (elt >= 0x10 && elt <= 0xFF)
      nextCode = readPCreators(group, pg);
    // log.debug('subgroups: ${pg.subgroups}');

    // Read the PrivateData
    if (Group.fromTag(nextCode) == group)
      readPData(group, pg);

    // log.debug('$ree _readPrivateGroup-end $pg');
    // log.up;
    return pg;
  }




// Check for Private Data 'in the wild', i.e. invalid.
// This group has no creators
  Element toPGLength(PrivateGroup pg, Element e) {
    PrivateGroupLength pgl = new PrivateGroupLength(e.tag, e);
    resultDS.add(pgl);
    pg.gLength = pgl;
    return pgl;
  }

// Reads 'Illegal' [PrivateElement]s in the range (gggg,0000) - (gggg,000F).
  PrivateElement toPIllegal(PrivateGroup pg, int group, TElement e) {
    PrivateElement pe;
    while (e.group == group && e.elt < 0x10) {
      PrivateTag tag = new PrivateTag.illegal(e.code);
      pe = new PrivateIllegal(e);
      pg.illegal.add(pe);
      resultDS.add(pe);
    }
    return pe;
  }

// Read the Private Group Creators.  There can be up to 240 creators
// with [Elt]s from 0x10 to 0xFF. All the creators come before the
// [PrivateData] [Element]s. So, read all the [PrivateCreator]s first.
// Returns when the first non-creator code is encountered.
// VR = LO or UN
// Returns the code of the next Element.
//TODO: this can be cleaned up and optimized if needed
  int readPCreators(int group, PrivateGroup pg, Element e) {

  }

  void readPData(int group, PrivateGroup pg, Element e) {

  }

  int readPDSubgroup(int code, PrivateSubGroup sg, Element e) {
    int nextCode = code;
    //?? while (pcTag.isValidDataCode(nextCode)) {
    PrivateCreator pc = sg.creator;
    PCTag pcTag = pc.tag;
    while (pc.inSubgroup(nextCode)) {
      PDTagKnown pdTagDef = pcTag.lookupData(nextCode);
      assert(nextCode == pdTagDef.code);
      pc.add(e);
      resultDS.add(e);
    }
  }*/
}



