// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;
import 'package:convert/src/json/reader/fast_reader_utils.dart';

class FastJsonReader {
  final List<List<List>> rootList;
  final TagRootDataset rds;
  Dataset cds;

  FastJsonReader(String json)
      : rootList = JSON.decode(json),
        rds = new TagRootDataset();

  RootDataset readRootDataset() {
    cds = rds;
    readFmi();
    readDataset(rootList[1]);
    return rds;
  }

  ElementList readFmi() {
    final fmi = rootList[0];
    final fmiElements = new MapAsList();
    for (var eList in fmi) {
      final e = readElement(eList);
      fmiElements.add(e);
    }
    return fmiElements;
  }

  List<TagItem> readItems(List<List> itemLists) {
    final items = <TagItem>[];
    for (var itemList in itemLists) {
      final item = readDataset(itemList);
      items.add(item);
    }
    return items;
  }

  Item readItem(List itemList) => readDataset(itemList);

  Dataset readDataset(List itemList) {
    //  final length = itemList.length;
    final parentDS = cds;
    final item = new TagItem(parentDS);
    cds = item;
    for (var eList in itemList) {
      cds.add(readElement(eList));
    }
    cds = parentDS;
    return item;
  }

  Element readElement(List eList) {
    final code = int.parse(eList[0]);
    final tag = Tag.lookupByCode(code);
    final vrIndex = vrIndexFromId(eList[1]);
    if (vrIndex == kSQIndex) {
      return readSequence(tag, vrIndex, eList);
    } else {
      return readSimpleElement(tag, vrIndex, eList);
    }
  }

  Element readSimpleElement(Tag tag, int vrIndex, List eList) {
    final values = readValueField(tag.code, vrIndex, eList[2]);
    return TagElement.make(tag, values, vrIndex);
  }

  SQ readSequence(Tag tag, int vrIndex, List eList) {
    if (vrIndex != kSQIndex || tag.vrIndex != kSQIndex)
      return invalidSequenceElement(eList);
    final values = readItems(eList[2]);
    return SQtag.make(tag, values);
  }
}
