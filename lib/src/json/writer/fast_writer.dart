// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';

import 'package:core/core.dart' hide Indenter;

import 'package:convert/src/bulkdata/bulkdata_list.dart';
import 'package:convert/src/json/writer/indenter.dart';

class FastJsonWriter {
  /// The [RootDataset] to be written.
  final RootDataset rds;

  /// The output [File] path.
  final String path;

  /// An indenting StringBuffer
  final Indenter sb;
  final BulkdataList bdList;

  /// The threshold, in number of bytes, beyond which a Value Field
  /// is move to a Bulkdata object.
  final int bulkdataThreshold;

  /// _true_ if _Bulkdata_ should be separated from _Metadata_.
  final bool separateBulkdata;

  /// _true_ if File Meta-Information should be written as part of
  /// the [RootDataset] being written.
  final bool includeFmi;

  FastJsonWriter(this.rds, this.path,
      {this.bulkdataThreshold = 1024,
      this.separateBulkdata = false,
      this.includeFmi = true,
      int increment = 2})
      : sb = new Indenter(increment),
        bdList = (separateBulkdata) ? new BulkdataList(path) : null {
    _separateBulkdata = separateBulkdata;
    _bdThreshold = bulkdataThreshold;
    _bdList = bdList;
  }

  FastJsonWriter.metadata(this.rds, this.path,
      {this.bulkdataThreshold = 1024,
      this.separateBulkdata = false,
      this.includeFmi = true,
      int increment = 2})
      : sb = new Indenter(increment),
        bdList = new BulkdataList(path) {
    _separateBulkdata = separateBulkdata;
    _bdThreshold = (separateBulkdata) ? bulkdataThreshold : -1;
  }

  String write() => _writeRootDataset(rds, sb);

  String _writeRootDataset(RootDataset rds, Indenter sb) {
    sb.indent('[');
    if (includeFmi) _writeFmi(rds, sb);
    _writeDataset(rds, '');
    sb.outdent(']');
    return sb.toString();
  }

  void _writeFmi(RootDataset rds, Indenter sb) {
    sb.indent('[');
    final fmi = rds.fmi.elements;
    final last = fmi.length - 1;
    for (var i = 0; i < last; i++)
      _writeElement(fmi.elementAt(i), isLast: false);
    _writeElement(fmi.elementAt(last), isLast: true);
    sb.outdent('],');
  }

  void _writeElement(Element e, {bool isLast}) {
    final comma = (isLast) ? '' : ',';
    if (e is SQ) {
      print('e: $e');
      _writeSQ(e, comma);
    } else {
      print('e: $e');
//      print('e.vr: ${e.vrIndex} tag.vr: ${e.tag.vrIndex}');
      _elementWriters[e.vrIndex](e, sb, comma);
    }
  }

  void _writeSQ(SQ e, String comma) {
    final items = e.items;
    if (items.isEmpty) {
      sb.writeln('["${e.hex}", "${e.vrId}", []]$comma');
    } else {
      print('WriteSQ: $e');
      sb.indent('["${e.hex}", "${e.vrId}", [', 2);
      _writeItems(e.items, comma);
      sb..outdent(']')..outdent(']$comma');
    }
  }

  void _writeItems(List<Item> items, String comma) {
    final last = items.length - 1;
    for (var i = 0; i < last; i++) _writeDataset(items.elementAt(i), ',');
    _writeDataset(items.elementAt(last), '');
  }

//  void _writeItem(Item item, String comma) => _writeDataset(item, comma);

  void _writeDataset(Dataset ds, String comma) {
    sb.indent('[');
    final elements = ds.elements;
    final last = elements.length - 1;
    for (var i = 0; i < last; i++)
      _writeElement(elements.elementAt(i), isLast: false);
    _writeElement(elements.elementAt(last), isLast: true);
    sb.outdent(']$comma');
  }


}

typedef void _ElementWriter(Element e, Indenter sb, String comma);

bool _separateBulkdata;
int _bdThreshold;
BulkdataList _bdList;

List<_ElementWriter> _elementWriters = <_ElementWriter>[
  _sqError, // no reformat
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

Null _sqError(Element e, Indenter sb, String comma) =>
    invalidElementIndex(e.vrIndex);

void _writeFloat(Element e, Indenter sb, String comma) {
  assert(e is FloatBase);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", ${e.values}]');
  } else {
  final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeInt(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", ${e.values}]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeOtherFloat(Element e, Indenter sb, String comma) {
  assert(e is FloatBase);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    (e.values.isEmpty) ? sb.writeln('["${e.hex}", "${e.vrId}", ""]$comma') : sb
        .writeln('["${e.hex}", "${e.vrId}", '
            '["InlineBinary", "${BASE64.encode(e.vfBytes)}"]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeOtherInt(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    (e.values.isEmpty) ? sb.writeln('["${e.hex}", "${e.vrId}", ""]') : sb
        .writeln(
        '["${e.hex}", "${e.vrId}", ["InlineBinary", '
            '"${BASE64.encode(e.vfBytes)}"]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeText(Element e, Indenter sb, String comma) {
  assert(e is Text);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", ["${e.values}"]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeString(Element e, Indenter sb, String comma) {
  assert(e is StringBase, '$e is not StringBase');
  final List<String> v = e.values;
  if (v.isEmpty) {
    sb.writeln('["${e.hex}", "${e.vrId}", []]$comma');
  }
  final nList = new List<String>(v.length);
  var vfLength = 0;
  for (var i = 0; i < v.length; i++) {
    final s = v.elementAt(i);
    vfLength += s.length;
    nList[i] = '"$s"';
    vfLength += nList.length - 1;
  }
  if (!_separateBulkdata || vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", [${nList.join(', ')}]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}


