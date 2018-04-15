//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
//
void main(List<String> args) {
  // ArgParser parser = getArgParser();

  final inFile = new File('C:/odw/sdk/encode/example/json/example.json');
  final s = inFile.readAsStringSync();
  final Map code = json.decode(s);
  print('json array(${code.length}');
  final Map ds0 = code[0];
  final Map ds1 = code[1];
  print('obj 0: $ds0');
  print('obj 1: $ds1');

  // Map dsx0 = toDataset(ds0);
//  Map dsx1 = toDataset(ds1);

 const encoder = const JsonEncoder.withIndent('  ');
 final pretty = encoder.convert(code);

  new File('C:/odw/sdk/encode/example/json/output.json')
  ..writeAsStringSync(pretty);
}

/// Convert a JSON [Map] to a [Dataset] [Map]
Map<int, TagElement> toDataset(Map<String, dynamic> jsMap) {
  final eMap = <int, TagElement>{};
  jsMap.forEach(decodeMap);
  return eMap;
}

// ignore: avoid_annotating_with_dynamic
void decodeMap(String s,  dynamic map) {
  final code = int.parse(s, radix: 16);
  String vrId;
  var vrIndex = kUNIndex;

  var values = const <TagElement>[];
  if (map.length != 0) {
    vrId = map['vr'];
    vrIndex = vrIndexFromId(vrId );
    values = map['Value'];
    if (values == null) {
      values = map['InlineBinary'];
      values ?? map['BulkDataUri'];
    }
  }
  //TODO: debug not finished
  final tag = Tag.lookupByCode(code, vrIndex);
  print('${tag.dcm}($vrId): $values');
}
