//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart' hide Indenter;
import 'package:converter/src/json/reader/json_reader_base.dart';

// ignore_for_file: only_throw_errors

class FastJsonReader extends JsonReaderBase {
  final List<List<List>> rootList;
  @override
  final TagRootDataset rds;
  @override
  Dataset cds;

  FastJsonReader(String s)
      : rootList = json.decode(s),
        rds = TagRootDataset.empty();

  List get fmiList => rootList[0];
  List get rdsList => rootList[1];

  void readFmi() => _readFmi();

  void _readFmi() {
    for (var entry in fmiList) {
      final e = readEntry(entry);
      rds.fmi[e.code] = e;
    }
  }

  @override
  RootDataset readRootDataset() {
    _readFmi();
    for (var entry in rdsList) rds.add(readEntry(entry));
    return rds;
  }

  @override
  void readItems(SQ sq, Iterable itemList) {
    for (var i = 0; i < itemList.length; i++)
      readItem(sq, sq.items.elementAt(i), itemList.elementAt(i));
  }

  @override
  Item readItem(SQ sequence, Item item, Iterable entries) {
    final parentDS = cds;
    cds = item;
    for (var entry in entries) {
      final e = readEntry(entry);
      cds.add(e);
    }
    cds = parentDS;
    return item;
  }

  Map<int, String> privateCreatorsMap = <int, String>{};
  Map<int, PCTag> knownPrivateCreators = <int, PCTag>{};

  Element readEntry(List entry) {
    print('entry: $entry');
    final code = int.parse(entry[0], radix: 16);
    final vrIndex = vrIndexFromId(entry[1]);
    final dynamic values = readValueField(entry[2]);
    Tag tag;
    var csg = 0;
    PCTag cPCTag;
    print('${dcm(code)} vr($vrIndex) : $values');
    if (isPublicCode(code)) {
      print('PTag: ${dcm(code)} : $values');
      tag = PTag.lookupByCode(code, vrIndex);
    } else if (Tag.isPDCode(code)) {
      print('PCTag: ${dcm(code)} : $values');
      final sg = Tag.pdSubgroup(code);
      if (sg > csg) {
        csg = sg;
        cPCTag = knownPrivateCreators[csg];
      }
      tag = PDTag.make(code, vrIndex, cPCTag);
    } else if (Tag.isPCCode(code)) {
      print('PDTag: ${dcm(code)} : $values');
      String name;
      if (vrIndex == kLOIndex) {
        name = values[0];
      } else if (vrIndex == kUNIndex) {
        name = ascii.decode(values);
      } else {
        if (values is Uint8List) {
          name = ascii.decode(values);
        } else {
          throw 'PCTag with token: $values';
        }
      }

      privateCreatorsMap[Tag.pcSubgroup(code)] = name;
      tag = PCTag.make(code, vrIndex, name);
      knownPrivateCreators[code] = tag;
      return readElement(code, [name], vrIndex);
    } else {
      print('entry: $entry');
      throw 'error';
    }
    return readElement(code, values, vrIndex);
  }

  Object readValueField(List vField) {
    print('vField: $vField');
    if (vField.length < 2) return vField;
    final Object key = vField[0];
    final Object value = vField[1];
    if (key == 'InlineBinary') return base64.decode(value);
    if (key == 'BulkDataUrl') return value;
    return vField;
  }

  @override
  Element readSimpleElement(int code, int vrIndex, Iterable values,
          [Dataset ds]) =>
      TagElement.makeFromValues(code, vrIndex, values, ds);

  @override
  SQ readSequence(int code, Iterable entries, int vrIndex, [Dataset ds]) {
    final tag = Tag.lookupByCode(code, vrIndex);
    if (vrIndex == kSQIndex &&
        (tag.vrIndex == kSQIndex || tag.vrIndex == kUNIndex)) {
      final length = entries.length;
      final items = List<TagItem>(length);
      final sq = SQtag.fromValues(tag, items, kSQIndex);
      // Add the empty Items
      for (var i = 0; i < length; i++) items[i] = TagItem.empty(cds, sq);
      readItems(sq, entries);
      return sq;
    }
    return badSequenceElement(entries);
  }

  static RootDataset fromString(String s) =>
      FastJsonReader(s).readRootDataset();
}
