// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

typedef void ValueFieldWriter(Element e, StringBuffer sb);

void writeValueField(Element e, StringBuffer sb) {
  vfWriters[e.vrIndex](e, sb);
  sb.write(']\n');
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

Null _sqError(Element e, StringBuffer sb) => invalidElementIndex(e.vrIndex);

void floatVF(Element e, StringBuffer sb) {
  assert(e is FloatBase);
  sb.write('${e.values}');
}

void intVF(Element e, StringBuffer sb) {
  assert(e is IntBase);
  sb.write('${e.values}');
}

void otherVF(Element e, StringBuffer sb) {
  assert(e is FloatBase || e is IntBase);
//  print('**** ${hex32(e.code)}');
//  sb.write('**** ${hex32(e.code)}\n');
  sb.write('"${BASE64.encode(e.vfBytes)}"]');
}

void textVF(Element e, StringBuffer sb) {
  assert(e is Text);
  sb.write('["${e.values}"]');
}

void stringVF(Element e, StringBuffer sb) {
  assert(e is StringBase);
  final v = e.values;
  final nList = new List<String>(v.length);
  for (var i = 0; i < v.length; i++) nList[i] = '"${v.elementAt(i)}"';
  sb.write('[${nList.join(', ')}]');
}
