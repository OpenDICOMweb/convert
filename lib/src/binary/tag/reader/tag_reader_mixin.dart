//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';

abstract class TagReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  ReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          DicomBytes bytes, int fmiEnd) =>
      TagRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, DicomBytes bytes]) =>
      TagItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element makeFromBytes(DicomBytes bytes, Dataset ds, {bool isEvr}) =>
      TagElement.makeFromBytes(bytes, ds, isEvr: isEvr);

  Element makeMaybeUndefinedFromBytes(DicomBytes bytes, Dataset ds,
          [TransferSyntax ts]) =>
      TagElement.makeMaybeUndefinedFromBytes(bytes, ds);

  Element makeSQFromBytes(Dataset parent,
          [Iterable<Item> items, DicomBytes bytes]) =>
      TagElement.makeSQFromBytes(parent, items, bytes);

  Element makePixelDataFromBytes(DicomBytes bytes,
          [TransferSyntax ts, VFFragments fragments]) =>
      TagElement.makePixelDataFromBytes(bytes, cds, ts);

  Element makeFromValues<V>(int code, int vrIndex, List<V> vList) =>
      TagElement.makeFromValues(code, vrIndex, vList, cds);
}
