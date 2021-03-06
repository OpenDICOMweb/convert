//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

// import 'dart:convert';

import 'package:core/core.dart' hide Indenter;
// import 'package:converter/src/json/reader/fast_reader_utils.dart';

const List<int> bulkdataVRs = const <int>[
  kDSIndex, kFLIndex, kFDIndex, kISIndex, kLTIndex,
  kOBIndex, kODIndex, kOFIndex, kOLIndex, kOWIndex,
  kSLIndex, kSSIndex, kSTIndex, kUCIndex, kULIndex,
  kUNIndex, kUSIndex, kUTIndex // No reformat
];

abstract class JsonReaderBase {
  // final List<List<List>> rootList;
  RootDataset get rds;
  Dataset get cds;
  set cds(Dataset ds);
  RootDataset readRootDataset();

  void readItem(SQ sequence, Item item, Iterable entries);

  SQ readSequence(int code, Iterable entries, int vrIndex, [Dataset ds]);

  Element readSimpleElement(int code, int vrIndex, Iterable values,
      [Dataset ds]);

  // **** End Interface

  RootDataset read() => readRootDataset();

  void readItems(SQ sq, Iterable itemList) {
    for (var i = 0; i < itemList.length; i++)
      readItem(sq, sq.items.elementAt(i), itemList.elementAt(i).entries);
  }

  Element readElement(int code, Object values, int vrIndex, [Dataset ds]) {
    final tag = Tag.lookupByCode(code, vrIndex);
    if (tag.vrIndex != vrIndex) {
      log.warn('vrIndex($vrIndex) != tag.vrIndex(${tag.vrIndex}');
    }
    if (vrIndex == kSQIndex) {
      return readSequence(code, values, vrIndex);
    } else {
      return readSimpleElement(code, vrIndex, values, ds);
    }
  }
}
