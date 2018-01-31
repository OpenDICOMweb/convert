// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart' hide Indenter;
import 'package:convert/src/json/writer/fast_writer_utils.dart';
import 'package:convert/src/json/writer/indenter.dart';

class FastJsonWriter {
  final StringBuffer sb;
  final RootDataset rds;
  final Indenter i;

  FastJsonWriter(this.rds, {int indent = 2})
      : i = new Indenter(indent),
        sb = new StringBuffer();

  String writeRootDataset(RootDataset rds) {
    sb.write('[\n');
    i.down;
    writeFmi(rds);
    writeDataset(rds);
    i.up;
    sb.write(']\n');
    return sb.toString();
  }

  void writeFmi(RootDataset rds) {
    sb.write('${i.indent}[\n');
    i.down;
    for(var e in rds.fmi.elements) writeSimpleElement(e);
    i.up;
    sb.write('${i.indent}]\n');
  }

  void writeItems(List<Item> items) => items.forEach(writeItem);

  void writeItem(Item item) => writeDataset(item);

  String writeDataset(Dataset ds) {
    sb.write('${i.indent}[\n');
    i.down;
    for (var e in ds.elements) {
      if (e is SQ) {
        writeSequence(e);
      } else {
        writeSimpleElement(e);
      }
    }
    i.up;
    sb.write('${i.indent}]\n');
  }

  void writeSimpleElement(Element e) {
    sb.write('${i.indent}["${e.hex}": "${e.vrId}", ');
    writeValueField(e, sb);
//[\    print('$e');
  }

  void writeSequence(SQ e) {
    sb.write('${i.indent}["${e.hex}": "${e.vrId}", [\n');
    i.down;
    writeItems(e.items);
    i.up;
    sb.write('${i.indent}]\n');
  }
}
