// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:convert/src/json/reader/json_reader_base.dart';

// ignore_for_file: only_throw_errors

class JsonReader extends JsonReaderBase {
  final Map<String, Map<String, dynamic>> rootMap;
  @override
  final TagRootDataset rds;
  @override
  Dataset cds;

  JsonReader(String s)
      : rootMap = json.decode(s),
        rds = new TagRootDataset.empty();

  @override
  RootDataset readRootDataset() {
    for (var entry in rootMap.entries) {
      final e = readEntry(entry);
      if (e.code >= 0x00020000 && e.code < 0x00030000) {
        rds.fmi.add(e);
      } else {
        rds.add(e);
      }
    }
    return rds;
  }

  @override
  Item readItem(SQ sequence, Item item, Iterable entries) {
    final parentDS = cds;
    cds = item;
    for (var entry in entries) {
      final e = readEntry(entry);
      print('e: $e');
      cds.add(e);
    }
    cds = parentDS;
    return item;
  }

  Map<int, String> privateCreatorsMap = <int, String>{};
  Map<int, PCTag> knownPrivateCreators = <int, PCTag>{};

  Element readEntry(MapEntry entry) {
    print('entry: ${entry.key}, ${entry.value}');
    final code = int.parse(entry.key, radix: 16);
    final Map vField = entry.value;
    print('vField: $vField');
    final vrIndex = vrIndexFromId(vField['vr']);
    final dynamic values = readValueField(vField);
    Tag tag;
    var csg = 0;
    PCTag cPCTag;
    print('${dcm(code)} vr($vrIndex) : $values');
    if (Tag.isPublicCode(code)) {
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

  Object readValueField(Map<String, dynamic> vField) {
    Object values = vField['Values'];
    if (values != null) return values;
    values = vField['InlineBinary'];
    if (values != null) return base64.decode(values);
    values = vField['BulkDataUrl'];
    if (values != null) return values;
    return parseError('Invalid values Map: $vField');
  }

  @override
  Element readSimpleElement(
    int code,
    Object value,
    int vrIndex,
  ) =>
      TagElement.makeFromCode(code, value, vrIndex);

  @override
  SQ readSequence(int code, Iterable entries, int vrIndex) {
    final tag = Tag.lookupByCode(code, vrIndex);
    if (vrIndex == kSQIndex &&
        (tag.vrIndex == kSQIndex || tag.vrIndex == kUNIndex)) {
      final length = entries.length;
      final items = new List<TagItem>(length);
      final sq = SQtag.make(tag, items, kSQIndex);
      // Add the empty Items
      for (var i = 0; i < length; i++)
        items[i] = new TagItem.empty(cds, sq);
      readItems(sq, entries);
      return sq;
    }
    return invalidSequenceElement(entries);
  }

  static RootDataset fromString(String s) =>
      new JsonReader(s).readRootDataset();

  static RootDataset fromFile(File file) => fromString(file.readAsStringSync());

  static RootDataset fromPath(String path) => fromFile(new File(path));
}