// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';



abstract class WriterMixin {
  StringBuffer get sb;
  RootDataset get rds;


  void writeRootDataset(RootDataset rds) =>
      writeDataset(rds);

  void writeItem(Item item) => writeDataset(item);

  void writeDataset(Dataset ds) {
    for (var e in ds) {
      if (e is SQ) {
        writeSequence(e);
      } else {
        writeSimpleElement(e);
      }
    }
  }

  void writeItems(List<Item> items) {
    for (var item in items) writeItem(item);
  }

  void writeSimpleElement(Element e) {
    sb.write('["${e.hex}": "${e.vrId}", ');
    writeValueField(e);
  }

  void writeSequence(SQ e) {
    sb.write('["${e.hex}": "${e.vrId}", ');
    indentIn;
    writeItems(e.items);
  }

  void writeValueField(Element e) =>
      vfWriters[e.vrIndex](e);

}
