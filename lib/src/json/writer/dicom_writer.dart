// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart' hide Indenter;
import 'package:convert/src/json/writer/dicom_writer_utils.dart';
import 'package:convert/src/json/writer/indenter.dart';

const String kEmptyValueField = '"Value": []'; // or ''
const String kEmptyItem = '{}';

class DicomJsonWriter {
  final Indenter sb;
  final RootDataset rds;
  DicomJsonWriter(this.rds, {int indent = 2})
      : sb = new Indenter();

  String writeRootDataset(RootDataset rds) {
    sb.writeln('{');
    sb.down;
    // Write FMI
    for (var e in rds.fmi.elements) writeSimpleElement(e);
    // Write other Elements
    for (var e in rds.elements) writeElement(e);
    sb.up;
    sb.writeln('}');
    return sb.toString();
  }

  void writeItems(List<Item> items) => items.forEach(writeItem);

  void writeItem(Item item) {
    if (item.isEmpty) {
      sb.writeln('${kEmptyItem}');
      return;
    }
    final length = item.elements.length;
    sb.indent('{');
    for (var i = 0; i < length - 1; i++)
    for (var e in item.elements) writeElement(e, isLast: false);
    writeElement(e, isLast: true);
    sb.outdent('}');
  }

  void writeElement(Element e) =>
      (e is SQ) ? writeSequence(e) : writeSimpleElement(e);

  void writeSimpleElement(Element e) {
    sb.write('"${e.hex}": {"vr": "${e.vrId}"');
    if (e.values.isNotEmpty) {
      sb.sb.write(', ');
      writeValueField(e, sb);
    }
    sb.sb.writeln('}');
  }


  void writeSequence(SQ e) {
    sb.write('"${e.hex}": {"vr": "${e.vrId}"');
    if (e.items.isEmpty) {
      sb.sb.writeln('}');
      return;
    }
    sb.sb.writeln(', "Value": [');
    sb.down;
    sb.down;
    writeItems(e.items);
    sb.up;
    sb.writeln(']');
    sb.up;
    sb.writeln('}');
  }
}

String emptySequenceValue() {
  sb.sb.writeln('}');
  return;
}