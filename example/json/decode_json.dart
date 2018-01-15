// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart';
import 'package:convert/convert.dart';

void main(List<String> args) {
  // ArgParser parser = getArgParser();

  File inFile = new File('C:/odw/sdk/encode/example/json/example.json');
  String s = inFile.readAsStringSync();
  Map code = JSON.decode(s);
  print('json array(${code.length}');
  Map ds0 = code[0];
  Map ds1 = code[1];
  print('obj 0: $ds0');
  print('obj 1: $ds1');

  // Map dsx0 = toDataset(ds0);
//  Map dsx1 = toDataset(ds1);

  JsonEncoder encoder = new JsonEncoder.withIndent('  ');
  String pretty = encoder.convert(code);
  // print(pretty);

  File outFile = new File('C:/odw/sdk/encode/example/json/output.json');
  outFile.writeAsStringSync(pretty);
}

/// Convert a JSON [Map] to a [Dataset] [Map]
Map<int, TagElement> toDataset(Map jsMap) {
  final eMap = <int, TagElement>{};
  jsMap.forEach((String s, Map map) {
    int code = int.parse(s, radix: 16);
    VR vr = VR.kUN;
    var values = const <TagElement>[];
    if (map.length != 0) {
      vr = VR.vrMap[map['vr']];

      values = map['Value'];
      if (values == null) {
        values = map['InlineBinary'];
        if (values == null) {
          values = map['BulkDataUri'];
        }
      }
    }
    //TODO: debug not finished
    Tag tag = Tag.lookupPublicCode(code, vr);
    print('${tag.dcm}($vr): $values');
    // Function type = vrToElement[vr];
    //print('type: $type');
    //Element e = vrToElement[vr](tag, values);
    //print(e);
  });
  return eMap;
}
