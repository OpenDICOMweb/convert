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

import 'package:core/core.dart';
import 'package:xml/xml.dart' as xml;
import 'package:converter/src/xml/reader/xml_reader_base.dart';


// ignore_for_file: only_throw_errors

class XmlReader extends XmlReaderBase {
  final xml.XmlDocument document;
  @override
  final TagRootDataset rds;
  @override
  Dataset cds;

  XmlReader(String s)
      : document = xml.parse(s),
        rds =  TagRootDataset.empty();

  @override
  RootDataset readRootDataset() {
    for (var element in document.children) {
      final e = readEntry(element);
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

  Element readEntry(xml.XmlNode entry) {
    final a0 = entry.attributes.firstWhere((a) => a.name.local == 'tag');
    final code = int.tryParse(a0.value, radix: 16);
    final a1 = entry.attributes.firstWhere((a) => a0.name.local == 'vr');
    final vrName = a1.value;
    final vrIndex = vrNameByIndex.indexOf(vrName);
    final valueElements = entry.children[0].children;



//    final Map vField = value;
//    final vrIndex = vrIndexFromId(vField['vr']);
    final values = readValueFields(valueElements);
    print('entry: $code, $vrName($vrIndex), $values');
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

  // TODO: implement
  List<Object> readValueFields(List<xml.XmlNode> vFields) => [];

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
  Element readSimpleElement(int code, int vrIndex, Iterable values,
          [Dataset ds]) =>
      TagElement.fromValues(code, vrIndex, values, ds);

  @override
  SQ readSequence(int code, Iterable entries, int vrIndex, [Dataset ds]) {
    final tag = Tag.lookupByCode(code, vrIndex);
    if (vrIndex == kSQIndex &&
        (tag.vrIndex == kSQIndex || tag.vrIndex == kUNIndex)) {
      final length = entries.length;
      final items =  List<TagItem>(length);
      final sq = SQtag.fromValues(tag, items, kSQIndex, ds);
      // Add the empty Items
      for (var i = 0; i < length; i++) items[i] =  TagItem.empty(cds, sq);
      readItems(sq, entries);
      return sq;
    }
    return badSequenceElement(entries);
  }

  static RootDataset fromString(String s) =>
       XmlReader(s).readRootDataset();
}
