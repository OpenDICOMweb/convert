// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

import 'package:convert/src/json/writer/indenter.dart';

typedef void ValueFieldWriter(Element e, Indenter sb, String comma);


void writeElement(Element e, Indenter sb, {bool isLast}) {
  final comma = (isLast) ? '' : ',';
  vfWriters[e.vrIndex](e, sb, comma);
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

void  _sqError(Element e, Indenter sb, String comma) =>
    invalidElementIndex(e.vrIndex);

void floatVF(Element e, Indenter sb, String comma) {
  assert(e is FloatBase);
  sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Value": ${e.values}}$comma');
}

void intVF(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Value": ${e.values}}$comma');
}

void otherVF(Element e, Indenter sb, String comma) {
  assert(e is FloatBase || e is IntBase);
  sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Base64": "${BASE64.encode(e.vfBytes)}"$comma');
}

void textVF(Element e, Indenter sb, String comma) {
  assert(e is Text);
  final length = e.values.length;
  if (length == 0) return;
  if (length == 1) {
    sb.write('"Value": ["${e.values.elementAt(0)}"]$comma');
    return;
  }
  log.error('Text with multiple values: $e');
}

void stringVF(Element e, Indenter sb, String comma) {
  assert(e is StringBase);
  final v = e.values;
  if (v.isEmpty) {
    sb.writeln('"${e.hex}": {"vr": "${e.vrId}", ""}$comma');
    return;
  }
  final nList = new List<String>(v.length);
  for (var i = 0; i < v.length; i++) nList[i] = '"${v.elementAt(i)}"$comma';
  sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Value": [${nList.join(', ')}]$comma');
}
