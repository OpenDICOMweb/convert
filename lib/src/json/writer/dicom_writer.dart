// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart' hide Indenter;
import 'package:convert/src/json/writer/dicom_writer_utils.dart';
import 'package:convert/src/json/writer/indenter.dart';

const String kEmptyValueField = '[]'; // or ''
const String kEmptyItem = '{}';

class DicomJsonWriter {
  final Indenter sb;
  final RootDataset rds;
  final Indenter i;
  DicomJsonWriter(this.rds, {int indent = 2})
      : i = new Indenter(indent),
        sb = new Indenter();

  String writeRootDataset(RootDataset rds) {
    sb.writeln('{');
    i.down;
    // Write FMI
    for (var e in rds.fmi.elements) writeSimpleElement(e);
    // Write other Elements
    for (var e in rds.elements) writeElement(e);
    i.up;
    sb.writeln('}');
    return sb.toString();
  }

  void writeItems(List<Item> items) => items.forEach(writeItem);

  void writeItem(Item item) {
    if (item.isEmpty) {
      sb.writeln('${kEmptyItem}');
      return;
    }
    sb.writeln('{');
    i.down;
    for (var e in item.elements) writeElement(e);
    i.up;
    sb.writeln('}');
  }

  void writeElement(Element e) =>
      (e is SQ) ? writeSequence(e) : writeSimpleElement(e);

  void writeSimpleElement(Element e) {
    sb.write('"${e.hex}": {"vr: ${e.vrId}"');
    if (e.values.isNotEmpty) {
      sb.write(', ');
      writeValueField(e, sb);
    }
    sb.writeln('}');
  }

  void writeSequence(SQ e) {
    sb.write('"${e.hex}": {"vr: ${e.vrId}"');
    if (e.items.isEmpty) {
      sb.writeln('}');
      return;
    }
    sb.writeln(', Value: [');
    i.down;
    i.down;
    writeItems(e.items);
    i.up;
    i.up;
    sb.writeln('${i.indent}]}');
  }
}
