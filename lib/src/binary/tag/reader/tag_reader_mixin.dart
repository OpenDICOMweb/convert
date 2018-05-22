//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

abstract class TagReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  ReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          Bytes bytes, int fmiEnd) =>
      new ByteRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, Bytes bytes]) =>
      new ByteItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element makeFromBytes(DicomBytes bytes) =>
      TagElement.makeFromBytes(bytes, cds);

  Element makeMaybeUndefinedFromBytes(DicomBytes bytes,
          [int vfLengthField, TransferSyntax ts, VFFragments _]) =>
      TagElement.makeMaybeUndefinedFromBytes(
          bytes, cds, vfLengthField, ts);

  Element makeSQFromBytes(Dataset parent,
                                 [Iterable<Item> items, DicomBytes bytes]) {
    final tag = lookupTagByCode(cds, bytes.code, bytes.vrIndex);
    return SQtag.fromBytes(parent, items, bytes, tag);
  }

  Element makeFromValues(int code, Iterable vList, int vrIndex) =>
  TagElement.makeFromValues(code, vList, vrIndex, cds);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(Dataset parent, int code, Iterable items,
          [int vfOffset, int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequenceFromCode(
          parent, code, items, vfLengthField, bytes);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Dataset parent, Tag tag, Iterable items,
          [int vfOffset, int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequenceFromTag(parent, tag, items, vfLengthField, bytes);
}
