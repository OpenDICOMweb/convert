// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart' hide Indenter;

import 'package:convert/src/json/writer/indenter.dart';

typedef void _ElementWriter(Element e, Indenter isb, String comma);

class FastJsonWriter {
  final Indenter isb;
  final RootDataset rds;

  FastJsonWriter(this.rds, {int increment = 2})
      : isb = new Indenter(increment);


  String write(RootDataset rds) => _writeRootDataset(rds, isb);
}

String _writeRootDataset(RootDataset rds, Indenter isb) {
  isb.indent('[');
  _writeFmi(rds, isb);
  writeDataset(rds, isb, "");
  isb.outdent(']');
  return isb.toString();
}

void _writeFmi(RootDataset rds, Indenter isb) {
  isb.indent('[');
  final fmi = rds.fmi.elements;
  final last = fmi.length - 1;
  for (var i = 0; i < last; i++)
    _writeElement(fmi.elementAt(i), isb, isLast: false);
  _writeElement(fmi.elementAt(last), isb, isLast: true);
  isb.outdent('],');
}

void _writeItems(List<Item> items, Indenter isb, String comma) {
  final last = items.length - 1;
  for (var i = 0; i < last; i++)
    _writeItem(items.elementAt(i), isb, ",");
  _writeItem(items.elementAt(last), isb, "");
}

void _writeItem(Item item, Indenter isb, String comma) => writeDataset(item, isb, comma);

void writeDataset(Dataset ds, Indenter isb, String comma) {
  isb.indent('[');
  final elements = ds.elements;
  final last = elements.length - 1;
  for (var i = 0; i < last; i++)
    _writeElement(elements.elementAt(i), isb, isLast: false);
  _writeElement(elements.elementAt(last), isb, isLast: true);
  isb.outdent(']$comma');
}

void _writeElement(Element e, Indenter isb, {bool isLast}) {
  final comma = (isLast) ? '' : ',';
  _elementWriters[e.vrIndex](e, isb, comma);
}

List<_ElementWriter> _elementWriters = <_ElementWriter>[
  _writeSQ,
  // no reformat
  // Maybe Undefined Lengths
  _otherInt, _otherInt, _otherInt,

  // EVR Long
  _otherInt, _otherFloat, _otherFloat,
  _stringVF, textVF, textVF,

  // EVR Short

  _stringVF, _stringVF, _intVF, _stringVF, _stringVF,
  _stringVF, _stringVF, floatVF, floatVF, _stringVF,
  _stringVF, textVF, _stringVF, _stringVF, _intVF,
  _intVF, textVF, _stringVF, _stringVF, _intVF, _intVF,
];

void _writeSQ(Element e, Indenter isb, String comma) {
  if(e is SQ) {
    final items = e.items;
    if (items.isEmpty) {
      isb.writeln('["${e.hex}", "${e.vrId}", []]$comma');
    } else {
      isb.indent('["${e.hex}", "${e.vrId}", [', 2);
      _writeItems(e.items, isb, comma);
      isb.outdent(']');
      isb.outdent(']$comma');
    }
  }
  log.error('e is not an SQ');
  assert(e is SQ);
}

/*
Null _sqError(Element e, Indenter isb, String comma) =>
    invalidElementIndex(e.vrIndex);
*/

void floatVF(Element e, Indenter isb, String comma) {
  assert(e is FloatBase);
  isb.writeln('["${e.hex}", "${e.vrId}", ${e.values}]');
}

void _intVF(Element e, Indenter isb, String comma) {
  assert(e is IntBase);
  isb.writeln('["${e.hex}", "${e.vrId}", ${e.values}]$comma');
}

void _otherFloat(Element e, Indenter isb, String comma) {
  assert(e is FloatBase);
  (e.values.isEmpty)
      ? isb.writeln('["${e.hex}", "${e.vrId}", ""]$comma')
      : isb.writeln(
          '["${e.hex}", "${e.vrId}", "${BASE64.encode(e.vfBytes)}"]$comma');
}

void _otherInt(Element e, Indenter isb, String comma) {
  assert(e is IntBase);
  (e.values.isEmpty)
      ? isb.writeln('["${e.hex}", "${e.vrId}", ""]')
      : isb.writeln(
          '["${e.hex}", "${e.vrId}", "${BASE64.encode(e.vfBytes)}"]$comma');
}

void textVF(Element e, Indenter isb, String comma) {
  assert(e is Text);
  isb.writeln('["${e.hex}", "${e.vrId}", ["${e.values}"]]$comma');
}

void _stringVF(Element e, Indenter isb, String comma) {
  assert(e is StringBase);
  final v = e.values;
  if (v.isEmpty) {
    isb.writeln('["${e.hex}", "${e.vrId}", []]$comma');
  }
  final nList = new List<String>(v.length);
  for (var i = 0; i < v.length; i++) nList[i] = '"${v.elementAt(i)}"';
  isb.writeln('["${e.hex}", "${e.vrId}", [${nList.join(', ')}]]$comma');
}
