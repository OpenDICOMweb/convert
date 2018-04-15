//  Copyright (c) 2016, 2017, 2018, 
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart';

import 'package:convert/src/json/writer/json_writer_base.dart';

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
  String writeRootDataset() {
    sb.indent('[');
    if (includeFmi) {
      sb.indent('[');
      writeElementList(rds.fmi.elements, ',');
      sb.outdent('],');
    }
    sb.indent('[');
    writeElementList(rds.elements, ',');
    sb..outdent(']')..outdent(']');
    return sb.toString();
  }

  @override
  void writeSimpleElement(Element e, String separator) {
    sb.startln('["${e.hex}", "${e.vrId}", ');
    valueWriters[e.vrIndex](e, sb);
    sb.endln(']$separator');
  }

  @override
  void writeEmptyElement(Element e, String separator) => (emptyIsList)
      ? sb.writeln('["${e.hex}", "${e.vrId}", []]$separator')
      : sb.writeln('["${e.hex}", "${e.vrId}"]$separator');

  @override
  void writeBulkdata(Element e, String separator, BulkdataUri url) =>
      sb.writeln('["BulkDataUri": "$url"]]$separator');

  @override
  void writeSQ(SQ e, String separator) {
    sb.indent('["${e.hex}", "${e.vrId}", [', 2);
    writeItems(e.items, '[', ']', ',');
    sb..outdent(']]$separator', 2);
  }

  @override
  void writeElementStart(Element e) =>
      sb.indent('["${e.hex}", "${e.vrId}", [', 2);

  @override
  void writeElementEnd(Element e, String separator) => sb.indent(']$separator');

  static List<_ValueWriters> valueWriters = <_ValueWriters>[
    _sqError,
    // Maybe Undefined Lengths
    _writeOtherInt, _writeOtherInt, _writeOtherInt,

    // EVR Long
    _writeOtherFloat, _writeOtherFloat, _writeOtherInt,
    _writeStrings, _writeText, _writeText,

    // EVR Short
    _writeStrings, _writeStrings, _writeInt, _writeStrings,
    _writeStrings, _writeStrings, _writeStrings, _writeFloat,
    _writeFloat, _writeStrings, _writeStrings, _writeText,
    _writeStrings, _writeStrings, _writeInt, _writeInt,
    _writeText, _writeStrings, _writeStrings, _writeInt,
    _writeInt // No reformat
  ];

  static Null _sqError(Element e, Indenter sb) =>
      invalidElementIndex(e.vrIndex);

  static void _writeFloat(Element e, Indenter sb) =>
      sb.write('[${e.values.join(', ')}]');

  static void _writeOtherFloat(Element e, Indenter sb) =>
      sb.write('["InlineBinary", "${base64.encode(e.vfBytes)}"]');

  static void _writeInt(Element e, Indenter sb) => sb.write('[${e.values.join
    (', ')}]');

  static void _writeOtherInt(Element e, Indenter sb) =>
      sb.write('["InlineBinary", "${base64.encode(e.vfBytes)}"]');

  static void _writeText(Element e, Indenter sb) => sb.write('["${e.value}"]');

  static String _toString(String s) => '"$s"';

  static void _writeStrings(Element e, Indenter sb) {
    if (e is StringBase) {
      final sList = e.values.map(_toString);
      sb
        ..write('[')
        ..writeAll(sList, ', ')
        ..write(']');
    } else {
      invalidElementError(e, 'Not a StringBase Element');
    }
  }
}

typedef void _ValueWriters(Element e, Indenter sb);
