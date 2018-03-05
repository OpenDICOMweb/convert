// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart';

import 'package:convert/src/json/writer/writer_base.dart';

class FastJsonWriter extends JsonWriterBase {
  FastJsonWriter(RootDataset rds, String path,
      {int bulkdataThreshold = 1024,
      bool separateBulkdata = false,
      bool includeFmi = true,
      int tabSize = 2})
      : super(rds, path,
            bulkdataThreshold: bulkdataThreshold,
            separateBulkdata: separateBulkdata,
            includeFmi: includeFmi,
            tabSize: tabSize);

  @override
  String writeRootDataset(RootDataset rds) {
    sb.indent('{');
    if (includeFmi) {
      for (var e in rds.fmi.elements) writeElement(e, ',');
    }
    writeElementList(rds.elements, ',');
    sb.outdent('}');
    return sb.toString();
  }

  @override
  void writeSimpleElement(Element e, String separator) {
    sb.startln('"${e.hex}": {"vr": "${e.vrId}", ');
    valueWriters[e.vrIndex](e, sb);
    sb.endln('}$separator');
  }

  @override
  void writeEmptyElement(Element e, String separator) => (emptyIsList)
      ? sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Values": []}$separator')
      : sb.writeln('"${e.hex}": {"vr": "${e.vrId}]$separator');

  @override
  void writeBulkdata(Element e, String separator, BulkdataUri url) =>
      sb.writeln('{"BulkDataUri": "$url"}}$separator');

  @override
  void writeSQ(SQ e, String separator) {
    sb.indent('"${e.hex}": {"vr": "${e.vrId}", "Values": [');
    if (e.items.isNotEmpty) writeItems(e.items, '{', '}', ',');
    sb.outdent(']}$separator');
  }

  @override
  void writeElementStart(Element e) =>
      sb.indent('"${e.hex}": {"vr": "${e.vrId}", ', 2);

  @override
  void writeElementEnd(Element e, String separator) => sb.indent('}$separator');

  static List<_ValueWriters> valueWriters = <_ValueWriters>[
    _sqError,
    // Maybe Undefined Lengths
    _writeOtherInt, _writeOtherInt, _writeOtherInt,

    // EVR Long
    _writeOtherFloat, _writeOtherFloat, _writeOtherInt,
    _writeStrings, _writeText, _writeText,

    // EVR Short
    _writeStrings, _writeStrings, _writeInt,     _writeStrings,
    _writeStrings, _writeStrings, _writeStrings, _writeFloat,
    _writeFloat,   _writeStrings, _writeStrings, _writeText,
    _writeStrings, _writeStrings, _writeInt,     _writeInt,
    _writeText,    _writeStrings, _writeStrings, _writeInt,
    _writeInt // no reformat
  ];

  static Null _sqError(Element e, Indenter sb) =>
      invalidElementIndex(e.vrIndex);

  static void _writeFloat(Element e, Indenter sb) =>
      sb.write('"Values": [${e.values.join(', ')}]');

  static void _writeOtherFloat(Element e, Indenter sb) =>
      sb.write('"InlineBinary": "${BASE64.encode(e.vfBytes)}"');

  static void _writeInt(Element e, Indenter sb) =>
      sb.write('"Values": [${e.values.join(', ')}]');

  static void _writeOtherInt(Element e, Indenter sb) =>
      sb.write('"InlineBinary": "${BASE64.encode(e.vfBytes)}"');

  static void _writeText(Element e, Indenter sb) =>
      sb.write('"Values": ["${e.value}"]');

  static String _toString(String s) => '"$s"';

  static void _writeStrings(Element e, Indenter sb) {
    if (e is StringBase) {
      final sList = e.values.map(_toString);
      sb
        ..write('"Values": [')
        ..writeAll(sList, ', ')
        ..write(']');
    } else {
      invalidElementError(e, 'Not a StringBase Element');
    }
  }
}

typedef void _ValueWriters(Element e, Indenter sb);
