// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// TODO: uncomment when ready to finish

import 'package:core/core.dart';

import 'package:convert/src/utilities/private_dataset.dart';

typedef Element ElementFrom(Element e);

typedef Element ElementMaker<V>(Tag tag, List<V> values, int vrIndex,
    [int vfLengthField]);

typedef Item ItemMaker(Dataset parent, SQ sq);

abstract class Converter {
  RootDataset get sRds;

  RootDataset get tRds;

  Dataset get currentSDS;
  set currentSDS(Dataset ds);

  Dataset get currentTDS;
  set currentTDS(Dataset ds);

  PrivateRootDataset get pRds;

  bool get doConvertUN;
  int _index;

  /// Creates a new Element from a tag, vrIndex and values.
  Element makeElement<V>(Tag tag, Iterable<V> values, int vrIndex,
      [int vfLengthField]);

  /// Creates a new Element from an Element.
  Element fromElement(Element e, int vrIndex);

  SQ makeSequence(Dataset parent, Tag tag, int nItems, [int vfLengthField]);

  Dataset makeItem(Dataset parent, SQtag sq);

  RootDataset convert() {
    _index = 0;
    currentTDS = tRds;
    _convertFmi(sRds);
    log.debug(tRds.fmi);
    convertDataset(sRds);
    log.debug('< @$_index  $tRds', -1);
    return tRds;
  }

  // Does not handle SQ or Private
  void _convertFmi(RootDataset sRds) {
    //sRds.fmi.forEach(convertFmiElement);
    for (var e in sRds.fmi) {
      final vrIndex = (doConvertUN) ? e.tag.vrIndex : e.vrIndex;
      tRds.fmi.add(fromElement(e, vrIndex));
    }
  }

  void convertDataset(Dataset ds) => ds.elements.forEach(convertElement);

  void convertElement(Element e) {
    _index++;
    log.debug('> @$_index convert: $e', 1);
    if (e is SQ) {
      convertSequence(e);
    } else {
      final vrIndex = (doConvertUN) ? e.tag.vrIndex : e.vrIndex;
      final eNew = fromElement(e, vrIndex);
      log.debug('| @$_index eNew: $eNew');
      currentTDS.add(eNew);
      if (eNew.tag.isPrivate) pRds.add(eNew);
    }
    log.debug('< @$_index convert: $e', -1);
  }

  void convertSQPrivate(Element e) {
    pRds.add(e);
    convertElement(e);
  }

  void convertSequence(SQ sSQ) {
    final tSQ =
        makeSequence(currentTDS, sSQ.tag, sSQ.items.length, sSQ.vfLengthField);
    currentTDS.add(fromElement(tSQ, sSQ.vrIndex));
    // pRds.push(tSQ);
    convertItems(sSQ, tSQ);
    // pRds.pop(tSQ);
  }

  void convertItems(SQ sSQ, SQ tSQ) {
    final sParentDS = currentSDS;
    final tParentDS = currentTDS;

    for (var sItem in sSQ.items) {
      log.debug('> @$_index $sItem', 1);
      currentSDS = sItem;
      currentTDS = makeItem(tParentDS, tSQ);
      convertDataset(sItem);
      log.debug('< @$_index $sItem', -1);
    }
    currentSDS = sParentDS;
    currentTDS = tParentDS;
    if (tSQ.tag.isPrivate) pRds.add(tSQ);
    currentTDS.add(fromElement(tSQ, sSQ.vrIndex));
  }
}

class TagConverter extends Converter {
  @override
  final RootDataset sRds;
  @override
  final TagRootDataset tRds;
  @override
  Dataset currentSDS;
  @override
  Dataset currentTDS;
  @override
  PrivateRootDataset pRds;
  @override
  bool doConvertUN;

  factory TagConverter(RootDataset sRds, {bool doConvertUN = false}) {
    final tRds = new TagRootDataset.empty();
    return new TagConverter._(sRds, tRds, doConvertUN);
  }

  TagConverter._(this.sRds, this.tRds, this.doConvertUN)
      : pRds = new PrivateRootDataset.empty();

  @override
  Element makeElement<V>(Tag tag, Iterable<V> values, int vrIndex,
          [int vfLengthField]) =>
      TagElement.make(tag, values, vrIndex, vfLengthField);

  @override
  Element fromElement(Element e, int vrIndex) =>
      TagElement.from(e, vrIndex ?? e.vrIndex);

  @override
  TagItem makeItem(Dataset parent, SQtag sq) => new TagItem.empty(parent, sq);

  @override
  SQtag makeSequence(Dataset parent, Tag tag, int nItems,
          [int vfLengthField]) =>
      new SQtag(tag, parent, new List<TagItem>(nItems), vfLengthField);
}

/* Urgent Jim Finish
class ProfiledDataset extends TagRootDataset {
  BDRootDataset original;

  ProfiledDataset(this.original, {bool replaceAllUids = true})
      : super.from(original);

  static RootDataset toProfiledDataset(RootDataset rds) {}
}
*/
