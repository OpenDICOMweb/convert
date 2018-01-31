// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

import 'package:convert/src/json/writer/indenter.dart';

typedef void ValueFieldWriter(Element e, Indenter sb);

void writeValueField(Element e, Indenter sb) {
  vfWriters[e.vrIndex](e, sb);
  //sb.write('}\n');
}

List<ValueFieldWriter> vfWriters = <ValueFieldWriter>[
  _sqError,
  // no reformat
  // Maybe Undefined Lengths
  otherVF, otherVF, otherVF,

  // EVR Long
  otherVF, otherVF, otherVF,
  stringVF, textVF, textVF,

  // EVR Short

  stringVF, stringVF, intVF, stringVF, stringVF,
  stringVF, stringVF, floatVF, floatVF, stringVF,
  stringVF, textVF, stringVF, stringVF, intVF,
  intVF, textVF, stringVF, stringVF, intVF, intVF,
];

Null _sqError(Element e, Indenter sb) => invalidElementIndex(e.vrIndex);

void floatVF(Element e, Indenter sb) {
  assert(e is FloatBase);
  sb.write('Value: ${e.values}');
}

void intVF(Element e, Indenter sb) {
  assert(e is IntBase);
  sb.write('Value: ${e.values}');
}

void otherVF(Element e, Indenter sb) {
  assert(e is FloatBase || e is IntBase);
  sb.write('Base64: "${BASE64.encode(e.vfBytes)}"');
}

void textVF(Element e, Indenter sb) {
  assert(e is Text);
  final length = e.values.length;
  if (length == 0) return;
  if (length == 1) {
    sb.write('Value: ["${e.values.elementAt(0)}"]');
    return;
  }
  log.error('Text with multiple values: $e');
}

void stringVF(Element e, Indenter sb) {
  assert(e is StringBase);
  final v = e.values;
  final nList = new List<String>(v.length);
  for (var i = 0; i < v.length; i++) nList[i] = '"${v.elementAt(i)}"';
  sb.write('Value: [${nList.join(', ')}]');
}
