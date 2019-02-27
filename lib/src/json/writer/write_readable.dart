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
import 'package:converter/src/json/writer/json_writer_base.dart';

// ignore_for_file: public_member_api_docs

typedef JsonValueToString = String Function(Element e, [Indenter sb]);

class ReadableJsonWriter extends JsonWriterBase {
  ReadableJsonWriter(RootDataset rds, String path,
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
    sb.indent('{');
    if (includeFmi) {
      sb.indent('fmi: [');
      writeElementList(rds.fmi.elements, ',');
      sb.outdent('],');
    }
    sb.indent('rds: [');
    writeElementList(rds.elements, ',');
    sb..outdent(']')..outdent('}');
    return sb.toString();
  }

  @override
  void writeSimpleElement(Element e, String separator) {
    if (e is UI) {
      final uids = e.uids;
      if (uids.length == 1) {
        final uid = uids[0];
        if (uid.isWellKnown) {
          sb.writeln('[${elementId(e)} ${uid.info}]$separator');
        } else {
          sb.writeln('[${elementId(e)} "${uid.asString}"]$separator');
        }
      }
    } else {
      final values = valueWriters[e.vrIndex](e);
      sb.writeln('[${elementId(e)} $values]$separator');
    }
  }

  @override
  void writeEmptyElement(Element e, String separator) => emptyIsList
      ? sb.writeln('[${elementId(e)} []]$separator')
      : sb.writeln('[${elementId(e)}]$separator');

  @override
  void writeSQ(SQ e, String separator) {
    sb.indent('[${elementId(e)} [', 2);
    writeItems(e.items, '[', ']', ',');
    sb.outdent(']]$separator', 2);
  }

  @override
  void writeElementStart(Element e) => sb.indent('[${elementId(e)} [', 2);

  @override
  void writeElementEnd(Element e, String separator) => sb.indent(']$separator');

  static List<JsonValueToString> valueWriters = <JsonValueToString>[
    _sqError,
    // Maybe Undefined Lengths
    _writeOtherInt, _writeOtherInt, _writeOtherInt,

    // EVR Long
    _writeOtherFloat, _writeOtherFloat, _writeOtherInt,
    _writeStrings, _writeText, _writeText,

    // EVR Short
    _writeStrings, _writeStrings, _writeInt, _writeStrings,
    _writeDates, _writeStrings, _writeDateTimes, _writeFloat,
    _writeFloat, _writeStrings, _writeStrings, _writeText,
    _writeStrings, _writeStrings, _writeInt, _writeInt,
    _writeText, _writeTimes, _writeStrings, _writeInt,
    _writeInt // No reformat
  ];

  // ignore: prefer_void_to_null
  static String _sqError(Element e, [Indenter sb]) =>
      badElementIndex(e.vrIndex);

  static String _writeFloat(Element e, [Indenter sb]) =>
      (e.values.length == 1) ? '${e.value}' : '[${e.values.join(', ')}]';

  static String _writeOtherFloat(Element e, [Indenter sb]) =>
      '[Base64 "${base64.encode(e.vfBytes)}"]';

  static String _writeInt(Element e, [Indenter sb]) =>
      (e.values.length == 1) ? '${e.value}' : '[${e.values.join(', ')}]';

  static String _writeOtherInt(Element e, [Indenter sb]) =>
      'Base64:"${base64.encode(e.vfBytes)}"';

  static String _writeDates(Element e, [Indenter sb]) {
    if (e is DA)
      return (e.values.length == 1) ? '${e.date}' : '[${e.dates.join(', ')}]';
    return badStringElement(e);
  }

  static String _writeTimes(Element e, [Indenter sb]) {
    if (e is TM)
      return (e.values.length == 1) ? '${e.time}' : '[${e.times.join(', ')}]';
    return badStringElement(e);
  }

  static String _writeDateTimes(Element e, [Indenter sb]) {
    if (e is DT)
      return (e.values.length == 1)
          ? '${e.dateTime}'
          : '[${e.dateTimes.join(', ')}]';
    return badStringElement(e);
  }

  static String _writeText(Element e, [Indenter sb]) => '"${e.value}"';

  static String _toString(String s, [Indenter sb]) => '"$s"';

  static String _writeStrings(Element e, [Indenter sb]) {
    if (e.values.length == 1)
      return '"${e.value}"';

    final sb = StringBuffer();
    if (e is StringBase) {
      final sList = e.values.map(_toString);
      sb
        ..write('[')
        ..writeAll(sList, ', ')
        ..write(']');
    } else {
      badStringElement(e);
    }
    return sb.toString();
  }
}
