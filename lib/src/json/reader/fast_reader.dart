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

  FastJsonReader(String json)
      : rootList = JSON.decode(json),
        rds = new TagRootDataset();

  RootDataset read() => _readRootDataset();


  RootDataset _readRootDataset() {
    _readFmi();
    _readDataset(rootList[1], rds);
    return rds;
  }

  void _readFmi() {
    final fmi = rootList[0];
    for (var eList in fmi) {
      final e = _readElement(eList, rds);
      rds.fmi.add(e);
    }
  }

  List<TagItem> _readItems(List<List> itemLists, Dataset parent) {
    final items = <TagItem>[];
    for (var itemList in itemLists) {
      final item = _readItem(itemList, parent);
      items.add(item);
    }
    return items;
  }

  Item _readItem(List itemList, Dataset parent) {
    final item = new TagItem(parent);
    _readDataset(itemList, item);
    return item;
  }

  void _readDataset(List itemList, Dataset ds) {
    for (var eList in itemList) {
      final e = _readElement(eList, ds);
      print('RDS: $e');
      ds.add(e);
    }
  }

  Element _readElement(List eList, Dataset ds) {
    final code = int.parse(eList[0]);
    final tag = Tag.lookupByCode(code);
    final vrIndex = vrIndexFromId(eList[1]);
    if (vrIndex == kSQIndex) {
      return _readSequence(tag, vrIndex, eList, ds);
    } else {
      return _readSimpleElement(tag, vrIndex, eList);
    }
  }

  Element _readSimpleElement(Tag tag, int vrIndex, List eList) {
    final values = readValueField(tag.code, vrIndex, eList[2]);
    return TagElement.make(tag, values, vrIndex);
  }

  SQ _readSequence(Tag tag, int vrIndex, List eList, Dataset ds) {
    if (vrIndex == kSQIndex && (tag.vrIndex == kSQIndex ||
        tag.vrIndex == kUNIndex)) {
      final values = _readItems(eList[2], ds);
      return SQtag.make(tag, values);
    }
    return invalidSequenceElement(eList);
  }
}
