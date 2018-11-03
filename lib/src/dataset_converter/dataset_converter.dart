//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:converter/src/dataset_converter/dataset_by_group.dart';

//typedef Element _ElementFrom(Element e);

//typedef Element _ElementMaker<V>(Tag tag, List<V> values, int vrIndex,
//    [int vfLengthField]);

//typedef Item _ItemMaker(Dataset parent, SQ sq);

abstract class Converter {
  // **** Interface
  RootDataset get sRds;

  RootDataset get tRds;

  Dataset get currentSds;
  set currentSds(Dataset ds);

  Dataset get currentTds;
  set currentTds(Dataset ds);

  RootDatasetByGroup get pRds;

  bool get doConvertUN;
  int _index;

  /// Creates a new Element from a tag, vrIndex and values.
  Element makeElement<V>(int code, Iterable<V> values, int vrIndex,
      [int vfLengthField]);

  /// Creates a new Element from an Element.
  Element fromElement(Element e, int vrIndex);

  SQ makeSequence(Dataset parent, Tag tag, int nItems, [int vfLengthField]);

  Dataset makeItem(Dataset parent, SQtag sq);
  // End of Interface

  RootDataset convert(RootDataset sRootDS, RootDataset tRootDS) {
    _index = 0;
    currentTds = tRootDS;
    _convertFmi(sRootDS, tRootDS);
    log.debug(tRootDS.fmi);
    convertRootDataset(sRootDS, tRootDS);
    log.debug('< @$_index  $tRootDS', -1);
    return tRootDS;
  }

  // Does not handle SQ or Private
  void _convertFmi(RootDataset sRds, RootDataset tRds) {
    for (var e in sRds.fmi.elements) {
      final vrIndex = doConvertUN ? e.tag.vrIndex : e.vrIndex;
      tRds.fmi.add(fromElement(e, vrIndex));
    }
  }

  void convertRootDataset(RootDataset sRootDS, RootDataset tRootDS) =>
      convertDataset(sRootDS, tRootDS);

  Element convertElement(Element eSource) {
    log.debug('> @$_index convert: $eSource', 1);
    Element eTarget;
    if (eSource is SQ) {
      eTarget = convertSequence(eSource);
    } else {
      eTarget = convertSimpleElement(eSource);
    }
    _index++;
    log.debug('< @$_index convert: $eSource', -1);
    return eTarget;
  }

  Element convertSimpleElement(Element eSrc) {
    var vrIndex = eSrc.vrIndex;
    final tagVRIndex = eSrc.tag.vrIndex;
    // Handle UN Elements specially
    if (eSrc.vrIndex == kUNIndex && doConvertUN) {
      vrIndex = (tagVRIndex > kMaxNormalVRIndex)
          ? convertSpecialVR(eSrc)
          : tagVRIndex;
    } else if (vrIndex != tagVRIndex) {
      invalidElement('vrIndex($vrIndex) != tagVRIndex($tagVRIndex)', eSrc);
    }
    final eDst = fromElement(eSrc, vrIndex);
    log.debug('| @$_index eNew: $eDst');
    currentTds.add(eDst);
    if (eDst.tag.isPrivate) pRds.add(eDst);
    return eDst;
  }

  // Note: if vr is a special then other Elements from
  // the source Dataset must be examined to determine the
  // correct VR for these VRs.
  int convertSpecialVR(Element e) {
    if (e.code == kPixelData) {}
    // Fix: temp
    return kUNIndex;
  }

  SQ convertSequence(SQ sSQ) {
    final tSQ =
        makeSequence(currentTds, sSQ.tag, sSQ.items.length, sSQ.vfLengthField);
    // currentTDS.add(tSQ);
    // pRds.push(tSQ);
    convertItems(sSQ, tSQ);
    // pRds.pop(tSQ);
    return tSQ;
  }

  void convertItems(SQ sSQ, SQ tSQ) {
    final sParentDS = currentSds;
    final tParentDS = currentTds;

    final sItems = sSQ.items.toList(growable: false);
    final tItems = List<Item>(sItems.length);
    for (var i = 0; i < sItems.length; i++) {
      currentSds = sItems[i];
      log.debug('> @$_index $currentSds[$i]', 1);
      currentTds = makeItem(tParentDS, tSQ);
      convertDataset(currentSds, currentTds);
      tItems[i] = currentTds;
      log.debug('< @$_index $currentSds[$i]', -1);
    }
    currentSds = sParentDS;
    currentTds = tParentDS;
    if (tSQ.tag.isPrivate) pRds.add(tSQ);
    currentTds.add(tSQ);
  }

  void convertDataset(Dataset sds, Dataset tds) {
    currentSds = sds;
    currentTds = tds;
    for (var e in sds.elements) {
      tds.add(convertElement(e));
    }
  }
}

class TagConverter extends Converter {
  @override
  final RootDataset sRds;
  @override
  final TagRootDataset tRds;
  @override
  Dataset currentSds;
  @override
  Dataset currentTds;
  @override
  RootDatasetByGroup pRds;
  @override
  bool doConvertUN;

  factory TagConverter(RootDataset sRds, {bool doConvertUN = false}) {
    final tRds = TagRootDataset.empty();
    return TagConverter._(sRds, tRds, doConvertUN);
  }

  TagConverter._(this.sRds, this.tRds, this.doConvertUN)
      : pRds = RootDatasetByGroup.empty();

  @override
  Element makeElement<V>(int code, Iterable<V> values, int vrIndex,
          [int vfLengthField]) =>
      TagElement.fromValues(code, vrIndex, values.toList(), currentSds);

  @override
  Element fromElement(Element e, int vrIndex) =>
      TagElement.fromValues(e.code, e.vrIndex, e.values, currentSds);

  @override
  TagItem makeItem(Dataset parent, SQtag sq) => TagItem.empty(parent, sq);

  @override
  SQtag makeSequence(Dataset parent, Tag tag, int nItems,
          [int vfLengthField]) =>
      SQtag(parent, tag, List<TagItem>(nItems));
}

/* Urgent Jim Finish
class ProfiledDataset extends TagRootDataset {
  ByteRootDataset original;

  ProfiledDataset(this.original, {bool replaceAllUids = true})
      : super.from(original);

  static RootDataset toProfiledDataset(RootDataset rds) {}
}
*/
