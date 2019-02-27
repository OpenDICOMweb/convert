//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:convert';

import 'package:core/core.dart';
import 'package:converter/src/binary/base/writer/writer.dart';
import 'package:converter/src/xml/writer/xml_writer_base.dart';

// ignore_for_file: public_member_api_docs

class XmlWriter extends XmlWriterBase {
  XmlWriter(RootDataset rds, String path,
      {int bulkdataThreshold = 1024,
      bool separateBulkdata = false,
      bool includeFmi = true,
      int tabSize = 2})
      : super(rds, path,
            bulkdataThreshold: bulkdataThreshold,
            separateBulkdata: separateBulkdata,
            includeFmi: includeFmi,
            tabSize: tabSize);

  XmlWriter.empty(
      {String path = '',
      int bulkdataThreshold = 1024,
      bool separateBulkdata = false,
      bool includeFmi = true,
      int tabSize = 2})
      : super(null, path,
            bulkdataThreshold: bulkdataThreshold,
            separateBulkdata: separateBulkdata,
            includeFmi: includeFmi,
            tabSize: tabSize);

  @override
  String writeRootDataset() {
    sb.indent('{');
    if (includeFmi) {
      for (final e in rds.fmi.elements)
        writeElement(e, ',');
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
  void writeEmptyElement(Element e, String separator) => emptyIsList
      ? sb.writeln('"${e.hex}": {"vr": "${e.vrId}", "Values": []}$separator')
      : sb.writeln('"${e.hex}": {"vr": "${e.vrId}]$separator');

  @override
  BulkdataUri writeBulkdata(Element e, String separator, BulkdataUri url) {
    sb.writeln('{"BulkDataUri": "$url"}}$separator');
    return url;
  }

  @override
  void writeSQ(SQ e, String separator) {
    sb.indent('"${e.hex}": {"vr": "${e.vrId}", "Values": [');
    if (e.items.isNotEmpty)
      writeItems(e.items, '{', '}', ',');
    sb.outdent(']}$separator');
  }

  @override
  void writeElementStart(Element e) =>
      sb.indent('"${e.hex}": {"vr": "${e.vrId}", ', 2);

  @override
  void writeElementEnd(Element e, String separator) => sb.indent('}$separator');

  static List<ValueWriter> valueWriters = <ValueWriter>[
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
    _writeInt // no reformat
  ];

  // ignore: prefer_void_to_null
  static Null _sqError(Element e, [Indenter sb]) =>
      invalidElementIndex(e.vrIndex);

  static void _writeFloat(Element e, [Indenter sb]) =>
      sb.write('"Values": [${e.values.join(', ')}]');

  static void _writeOtherFloat(Element e, [Indenter sb]) =>
      sb.write('"InlineBinary": "${base64.encode(e.vfBytes)}"');

  static void _writeInt(Element e, [Indenter sb]) =>
      sb.write('"Values": [${e.values.join(', ')}]');

  static void _writeOtherInt(Element e, [Indenter sb]) =>
      sb.write('"InlineBinary": "${base64.encode(e.vfBytes)}"');

  static void _writeText(Element e, [Indenter sb]) =>
      sb.write('"Values": ["${e.value}"]');

  static String _toString(String s) => '"$s"';

  static void _writeStrings(Element e, [Indenter sb]) {
    if (e is StringBase) {
      final sList = e.values.map(_toString);
      sb
        ..write('"Values": [')
        ..writeAll(sList, ', ')
        ..write(']');
    } else {
      badStringElement(e);
    }
  }
}
