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
          DicomBytes bytes, int fmiEnd) =>
      new ByteRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, DicomBytes bytes]) =>
      new ByteItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element makeFromDicomBytes(DicomBytes bytes, Dataset ds, {bool isEvr}) =>
      TagElement.makeFromDicomBytes(bytes, ds, isEvr: isEvr);

  Element makeMaybeUndefinedFromDicomBytes(DicomBytes bytes, Dataset ds,
          [TransferSyntax ts]) =>
      TagElement.makeMaybeUndefinedFromDicomBytes(bytes, ds);

  Element makeSQFromDicomBytes(Dataset parent,
          [Iterable<Item> items, DicomBytes bytes]) =>
      TagElement.makeSQFromDicomBytes(parent, items, bytes);

  Element makePixelDataFromDicomBytes(DicomBytes bytes,
          [TransferSyntax ts, VFFragments fragments]) =>
      TagElement.makePixelDataFromDicomBytes(bytes, cds, ts);

  Element makeFromValues<V>(int code, int vrIndex, List<V> vList) =>
      TagElement.makeFromValues(code, vrIndex, vList, cds);

/*  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(Dataset parent, int code, Iterable items,
          [int vfOffset, int vfLengthField, DicomBytes bytes]) =>
      TagElement.makeSequenceFromCode(
          parent, code, items, vfLengthField, bytes);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Dataset parent, Tag tag, Iterable items,
          [int vfOffset, int vfLengthField, DicomBytes bytes]) =>
      TagElement.makeSequenceFromTag(parent, tag, items, vfLengthField, bytes);
  */
}
