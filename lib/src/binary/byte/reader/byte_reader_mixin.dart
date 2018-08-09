//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';

abstract class ByteReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  ReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          DicomBytes bytes, int fmiEnd) =>
      new ByteRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, DicomBytes bytes]) =>
      new ByteItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element makeFromBytes(DicomBytes bytes, Dataset ds, {bool isEvr}) =>
      ByteElement.makeFromBytes(bytes, ds, isEvr: isEvr);

  Element makeMaybeUndefinedFromBytes(
          DicomBytes bytes,  Dataset ds) =>
      ByteElement.makeMaybeUndefinedFromBytes(bytes, ds);

  Element makePixelDataFromBytes(DicomBytes bytes,
          [TransferSyntax ts, VFFragments fragments]) =>
      ByteElement.makePixelDataFromBytes(bytes, ts, fragments, cds);

  Element makeSQFromBytes(Dataset parent,
          [Iterable<Item> items, DicomBytes bytes]) =>
      SQbytes.fromBytes(parent, items, bytes);

  Element makeFromValues<V>(int code, int vrIndex, List<V> vList) =>
      ByteElement.makeFromValues(code, vrIndex, vList, isEvr: true, ds: cds);
}
