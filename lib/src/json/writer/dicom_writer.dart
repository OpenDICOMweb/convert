// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart';


typedef void _ElementWriter(Element e, Indenter isb, String comma);

class DicomJsonWriter {
  final Indenter isb;
  final RootDataset rds;

  DicomJsonWriter(this.rds, {int increment = 2})
      : isb = new Indenter(increment);

  String write(RootDataset rds) => _writeRootDataset(rds, isb);
}

String _writeRootDataset(RootDataset rds, Indenter isb) {
  isb.down('{');
  _writeFmi(rds, isb);

  final elements = rds.elements;
  final last = elements.length - 1;
  for (var i = 0; i < last; i++)
    _writeElement(elements.elementAt(i), isb, isLast: false);
  _writeElement(elements.elementAt(last), isb, isLast: true);
  isb.up('}');
  return isb.toString();
}

void _writeFmi(RootDataset rds, Indenter isb) {
  final fmi = rds.fmi;
  final last = fmi.length - 1;
  for (var i = 0; i < last; i++)
    _writeElement(fmi[i], isb, isLast: false);
  _writeElement(fmi[last], isb, isLast: true);
}

void _writeItems(List<Item> items, Indenter isb, String comma) {
  final last = items.length - 1;
  for (var i = 0; i < last; i++) _writeItem(items.elementAt(i), isb, ',');
  _writeItem(items.elementAt(last), isb, '');
}

void _writeItem(Item item, Indenter isb, String comma) =>
    writeDataset(item, isb, comma);

void writeDataset(Dataset ds, Indenter isb, String comma) {
  isb.down('{');
  final elements = ds.elements;
  final last = elements.length - 1;
  for (var i = 0; i < last; i++)
    _writeElement(elements.elementAt(i), isb, isLast: false);
  _writeElement(elements.elementAt(last), isb, isLast: true);
  isb.up('}$comma');
}

String writeElement(Element e, {bool isLast}) {
  final isb = new Indenter();
  _writeElement(e, isb, isLast: isLast);
  return isb.toString();
}

void _writeElement(Element e, Indenter isb, {bool isLast}) {
  final comma = (isLast) ? '' : ',';
  _elementWriters[e.vrIndex](e, isb, comma);
}

List<_ElementWriter> _elementWriters = <_ElementWriter>[
  _writeSQ, // no reformat
  // Maybe Undefined Lengths
  _writeOtherInt, _writeOtherInt, _writeOtherInt,

  // EVR Long
  _writeOtherFloat, _writeOtherFloat, _writeOtherInt,
  _writeString, _writeText, _writeText,

  // EVR Short
  _writeString, _writeString, _writeInt, _writeString, _writeString,
  _writeString, _writeString, _writeFloat, _writeFloat, _writeString,
  _writeString, _writeText, _writeString, _writeString, _writeInt,
  _writeInt, _writeText, _writeString, _writeString, _writeInt, _writeInt,
];

void _writeSQ(Element e, Indenter isb, String comma) {
  if (e is SQ) {
    final items = e.items;
    if (items.isEmpty) {
      isb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Values": []}$comma');
    } else {
      isb.down('"${e.hex}": {"vr": "${e.vrId}", "Values": [', 2);
      _writeItems(e.items, isb, comma);
      isb..up(']')..up('}$comma');
    }
  }
  log.error('$e is not an SQ');
  assert(e is SQ);
}

void _writeFloat(Element e, Indenter sb, String comma) {
  assert(e is Float);
  sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Value": ${e.values}}$comma');
}

void _writeInt(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Value": ${e.values}}$comma');
}

void _writeOtherFloat(Element e, Indenter sb, String comma) {
  assert(e is Float);
  sb.writeln(
      '"${e.hex}": {"vr": "${e.vrId}", '
          '"Base64": "${BASE64.encode(e.vfBytes)}"}$comma');
}

void _writeOtherInt(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  sb.writeln(
      '"${e.hex}": {"vr": "${e.vrId}", '
          '"Base64": "${BASE64.encode(e.vfBytes)}"}$comma');
}

void _writeText(Element e, Indenter sb, String comma) {
  assert(e is Text);
  final length = e.values.length;
  if (length == 0) return;
  if (length == 1) {
    sb.writeln('"${e.hex}": {"vr": "${e.vrId}", '
                 '"Value": ["${e.values.elementAt(0)}"]}$comma');
    return;
  }
  log.error('Text with multiple values: $e');
}

void _writeString(Element e, Indenter sb, String comma) {
  assert(e is StringBase);
  final v = e.values;
  if (v.isEmpty) {
    sb.writeln('"${e.hex}": {"vr": "${e.vrId}", ""}$comma');
    return;
  }
  final nList = new List<String>(v.length);
  for (var i = 0; i < v.length; i++) nList[i] = '"${v.elementAt(i)}"';
  sb.writeln(
      '"${e.hex}": {"vr": "${e.vrId}", "Value": [${nList.join(', ')}]}$comma');
}
