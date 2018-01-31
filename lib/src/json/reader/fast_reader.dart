// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;
import 'package:convert/src/json/reader/fast_utils.dart';


class FastJsonReader {
  final List<List<List>> rootList;
  final TagRootDataset rds;
  Dataset cds;

  FastJsonReader(String json)
      : rootList = JSON.decode(json),
        rds = new TagRootDataset();

  String readRootDataset() {
    cds = rds;
    readFmi();
    readDataset(rds);
  }

  void readFmi() {
    final fmi = rootList[0];
    for(var e in fmi) {
      readSimpleElement(e);
    }
  }

  void readItems(List<Item> items) => items.forEach(readItem);

  void readItem(Item item) => readDataset(item);
  
  String readDataset(Dataset ds) {
    final rdsList = rootList[1];
    final length = rdsList.length;
    final parentDS = cds;
    cds = makeDataset(parentDS);
    final eList = new MapAsList(cds);


    for (var eList in eList) {
      final int code = eList[0];
      final vrIndex = vrIndexFromId(eList[1]);
      Element e;
      if (vrIndex == kSQIndex) {
        e = readSequence(code, vrIndex, eList);
      } else {
        e = readSimpleElement(code, vrIndex, eList);
      }

    }


  }

  Element readSimpleElement(int code, int vrIndex, List eList) {
    final values = readValueField(code, vrIndex,  eList);
    return makeElement(code, vrIndex, values);
  }

  SQ readSequence(int code, int vrIndex, List eList) {
    final int code = eList[0];
    if (eList[1] != 'SQ') return invalidSequenceElement(eList);
    final int vrIndex = vrIndexFromId(e[1]);

    final values = readItems(eList[2]);
    return makeSequence()


  }
}
