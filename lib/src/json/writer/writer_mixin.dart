// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

typedef void ValueFieldWriter(Element e, StringBuffer sb);

abstract class WriterMixin {
  StringBuffer get sb;
  void writeSequence(SQ e, StringBuffer sb);
  static void otherVF(Element e, StringBuffer sb);
  static void intVF(Element e, StringBuffer sb);
  static void floatVF(Element e, StringBuffer sb);
  static void stringVF(Element e, StringBuffer sb);
  static void textVF(Element e, StringBuffer sb);


  void writeRootDataset(RootDataset rds, StringBuffer sb) =>
      writeDataset(rds, sb);

  void writeItem(Item item, StringBuffer sb) => writeDataset(item, sb);

  void writeDataset(Dataset ds, StringBuffer sb) {
    for (var e in ds) {
      if (e is SQ) {
        writeSequence(e, sb);
      } else {
        writeElement(e, sb);
      }
    }
  }

  void writeItems(List<Item> items, StringBuffer sb) {
    for (var item in items) writeItem(item, sb);
  }

  void writeElement(Element e, StringBuffer sb) {
    sb.write('["${e.hex}": "${e.vrId}", ');
    writeValueField(e, sb);
  }

  void writeValueField(Element e, StringBuffer sb) =>
      vfWriters[e.vrIndex](e, sb);

  static List<ValueFieldWriter> vfWriters = <ValueFieldWriter>[
    _sqError,
    // no reformat
    // Maybe Undefined Lengths
    otherVF, otherVF, otherVF,

    // EVR Long
    otherVF, otherVF, otherVF,
    stringVF, textVF, textVF,

    // EVR Short

    stringVF, stringVF, intVF, stringVF, stringVF,
    stringVF, stringVF, floatVF, floatVF, stringVF,
    stringVF, textVF, stringVF, stringVF, intVF,
    intVF, textVF, stringVF, stringVF, intVF, intVF,
  ];

  static Null _sqError(Element e, StringBuffer sb) =>
      invalidElementIndex(e.vrIndex);

}
