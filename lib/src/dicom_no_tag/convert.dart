// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:dictionary/dictionary.dart';
import 'package:core/core.dart';

Logger log = new Logger('convert');

typedef Element<I, V> Maker<I, V>(I id, List<V> values, [int vfLength]);

class DSConverter {
  final RootByteDataset sourceRoot;
  final RootTDataset targetRoot;
  ByteDataset sourceDS;
  TDataset targetDS;
  PCTag creator;

  DSConverter(this.sourceRoot)
      : targetRoot = new RootTDataset(
            path: sourceRoot.path,
            hadUndefinedLength: sourceRoot.hadUndefinedLength) {
    sourceDS = sourceRoot;
    targetDS = targetRoot;
  }

  TDataset run() {
    Iterable<ByteElement> elements = sourceDS.elements;
    for (ByteElement e in elements) {
      TElement te = tElement(e);
      targetDS[te.code] = te;
    }
    return targetDS;
  }

  Tag getTag(ByteElement e) {
    int code = e.code;
    if (Tag.isPublicCode(code)) {
      return PTag.lookupCode(code);
    } else if (Tag.isPrivateCreatorCode(code)) {
      var creator = new PCTag(code, e.vr, e.value);
      return creator;
    } else if (Tag.isValidPrivateDataTag(code, creator.code)) {
      var tag = creator.dataTags[code];
      return tag;
    } else {
      throw 'couldn\'t get tag: ${e.info}';
    }
  }

  TElement tElement(ByteElement e) {
    if (e is ByteSQ) return tSequence(e);
    var tag = getTag(e);
    VR vr = (tag.vr == VR.kUN) ? tag.vr : e.vr;
    if (vr != tag.vr) log.warn('e.vr($vr) and tag.vr(${tag.vr}) are not equal');
    return TElement.make(tag, e.vfBytes);
  }

  SQ tSequence(ByteSQ sq) {
    Tag tag = getTag(sq);
    var elements = sourceDS.elements;
    List<TItem> tItems = new List<TItem>(sq.items.length);
    for (ByteItem bItem in sq.items) {
      Map<int, TElement> tMap = <int, TElement>{};
      for (ByteElement e in elements) {
        TElement te = tElement(e);
        tMap[te.code] = te;
      }
      tItems.add(new TItem(targetDS, tMap, bItem.vfLength));
    }
    return new SQ(tag, tItems, sq.vfLength);
  }

  void group(int group, ByteElement e) {
  }
}
/*

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
  PrivateGroup readPrivateGroup(int group, List<ByteElement> bElements, int
  index) {
    ByteElement be = bElements[index];
    assert(Group.isPrivate(be.group), "Non Private Group ${Tag.toHex(code)}");

    var pg = new PrivateGroup(group);
  //  targetDS.privateGroups.add(pg);

    // Private Group Lengths are retired but still might be present.
    if (be.elt == 0x0000) {
      var te = tElement(index, be);
      targetDS.add(te);
      pg.gLength = te;
      index++;
      be = bElements[index];
    }
    // There should be no [TElement]s with [Elt] numbers between 0x01 and 0x0F.
    // [Elt]s between 0x01 and 0x0F are illegal.
    if (be.elt < 0x0010) nextCode = _readPIllegal(group, be, pg);

    // [Elt]s between 0x10 and 0xFF are [PrivateCreator]s.

    if (elt >= 0x10 && elt <= 0xFF)
      nextCode = _readPCreators(group, code, isExplicitVR, pg);
    // log.debug('subgroups: ${pg.subgroups}');

    // Read the PrivateData
    if (Group.fromTag(nextCode) == group)
      _readAllPData(group, nextCode, isExplicitVR, pg);

    // log.debug('$ree _readPrivateGroup-end $pg');
    // log.up;
    return pg;
  }

*/
/*
/ Check for Private Data 'in the wild', i.e. invalid.
// This group has no creators
  int _readPGLength(int group, int code, ByteElement e, PrivateGroup pg) {
    // log.debugDown('$rbb _readPGroupLength: ${Tag.toDcm(code)}');

   // TElement e = _readElement(code, isExplicitVR);
    // log.debug('$rmm _readPGroupLength e: $e');
    PrivateGroupLength pgl = new PrivateGroupLength(e.tag, e);
    ds.add(pgl);
    pg.gLength = pgl;
    // log.debugUp('$ree _readPGroupLength pe: ${pgl.info}');
    return _readTagCode();
  }
*/

/*

// Reads 'Illegal' [PrivateElement]s in the range (gggg,0000) - (gggg,000F).
  int _readPIllegal(int group, ByteElement e, PrivateGroup pg) {
    // log.down;
    // log.debug('$rbb _readPIllegal: ${Tag.toDcm(code)}');
    int nextCode = code;
    int g;
    int elt;
    while (g == group && elt < 0x10) {
      // log.debug('$rbb _readPIllegal: ${Tag.toDcm(code)}');
      PrivateTag tag = new PrivateTag.illegal(code);
      TElement e = _readElement(tag.code, isExplicitVR);
      // log.debug('$rmm _readPIllegal e: $e');
      PrivateElement pe = new PrivateIllegal(e);
      pg.illegal.add(pe);
      ds.add(pe);
      // log.debug('$ree _readPIllegal pe: ${pe.info}');
      // log.up;

      // Check the next TagCode.
      nextCode = _readTagCode();
      g = Group.fromTag(nextCode);
      elt = Elt.fromTag(nextCode);
      // log.debug('$rmm Next group(${Group.hex(g)}), Elt(${Group.hex(g)})');
    }
    return nextCode;
  }

// Read the Private Group Creators.  There can be up to 240 creators
// with [Elt]s from 0x10 to 0xFF. All the creators come before the
// [PrivateData] [TElement]s. So, read all the [PrivateCreator]s first.
// Returns when the first non-creator code is encountered.
// VR = LO or UN
// Returns the code of the next TElement.
//TODO: this can be cleaned up and optimized if needed
  int _readPCreators(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    int nextCode = code;
    int g;
    int elt;
    do {
      VR vr;
      int vfLength;
      // **** read PCreator
      if (isExplicitVR) {
        vr = _readExplicitVR();
        // log.debug('$rmm _readPCreator: $vr');
        if (vr != VR.kLO && vr != VR.kUN) throw 'Bad Private Creator VR($vr)';
        vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      } else {
        // log.debug(
        //    '$rmm _readImplicitVR: ${Tag.toDcm(nextCode)} vfLength
        // ($vfLength})');
        vr = VR.kUN;
        vfLength = readUint32();
      }
      // Read the Value Field for the creator token.
      List<String> values = _readDcmUtf8VF(vfLength);
      if (values.length != 1) throw 'InvalidCreatorToken($values)';
      String token = values[0];
      // log.debug('nextCode: $nextCode');
      var tag = new PCTag(nextCode, vr, token);
      // log.debug('Tag: $tag');
      LO e = new LO(tag, values);
      // log.debug('LO: ${e.info}');
      // log.debug('LO.code: $nextCode');
      // log.debug('e.tag: ${e.tag.info}');
      // log.debug('e: ${e.info}');
      var pc = new PrivateCreator(e);
      // log.debug('$ree _readTElement: ${pc.info}');
      // log.up;
      var psg = new PrivateSubGroup(pg, pc);
      // log.debug('$rmm _readTElement: pc($pc)');
      // log.debug('$rmm _readTElement: $psg');
      ds.add(pc);
      // **** end read PCreator

      nextCode = _readTagCode();
      g = Group.fromTag(nextCode);
      elt = Elt.fromTag(nextCode);
      // log.debug('$rmm Next group(${Group.hex(g)}), Elt(${Group.hex(g)})');
    } while (g == group && (elt >= 0x10 && elt <= 0xFF));

    // log.debug('$ree readAllPCreators-end: $pg');
    // log.up;
    return nextCode;
  }

  void _readAllPData(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    // Now read the [PrivateData] [Element]s for each creator, in order.
    // log.down;
    // log.debug('$rbb _readAllPData');
    int nextCode = code;
    while (group == Group.fromTag(nextCode)) {
      // log.debug('nextCode: ${Tag.toDcm(nextCode)}');
      var sgIndex = Elt.fromTag(nextCode) >> 8;
      // log.debug('sgIndex: $sgIndex');
      var sg = pg[sgIndex];
      // log.debug('Subgroup: $sg');
      if (sg == null) {
        // log.warn('This is a Subgroup without a creator');
        var creator = new PrivateCreator.phantom(nextCode);
        sg = new PrivateSubGroup(pg, creator);
      }
      // log.debug('Subgroup: $sg');
      nextCode = _readPDSubgroup(nextCode, isExplicitVR, sg);
      // log.debug('Subgroup: $sg');
      // log.debug('nextCode: nextCode');
    }
    // log.debug('$ree _readAllPData-end');
    // log.up;
  }

  int _readPDSubgroup(int code, bool isExplicitVR, PrivateSubGroup sg) {
    int nextCode = code;
    //?? while (pcTag.isValidDataCode(nextCode)) {
    PrivateCreator pc = sg.creator;
    PCTag pcTag = pc.tag;
    // log.debug('pdInSubgroupt${Tag.toDcm(nextCode)}: ${pc.inSubgroup(nextCode)
    // }');
    while (pc.inSubgroup(nextCode)) {
      // log.down;
      // log.debug('$rbb _readPDataSubgroup: base(${Elt.hex(pc.base)}), '
      //    'limit(${Elt.hex(pc.limit)})');

      PDTagKnown pdTagDef = pcTag.lookupData(nextCode);
      assert(nextCode == pdTagDef.code);
      // log.debug('_readPDataSubgroup: pdTag: ${pdTagDef.info}');
      TElement e = _readElement(nextCode, isExplicitVR);
      // log.debug('_readPDataSubgroup: e: ${e.info}');
      //  PrivateElement pd = new PrivateData(pdTagDef, e);
      //  // log.debug('_readPDataSubgroup: pd: ${pd.info}');
      pc.add(e);
      // log.debug('_readPDataSubgroup: pc: ${pc.info}');
      ds.add(e);

      // log.debug('$rmm readPD: ${e.info})');
      // log.up;
      nextCode = _readTagCode();
    }
    return nextCode;
  }
}

*/
