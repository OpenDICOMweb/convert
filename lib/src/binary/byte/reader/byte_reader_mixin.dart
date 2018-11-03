//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';
import 'package:core/vf_fragments.dart';

abstract class ByteReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  DicomReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          DicomBytes bytes, int fmiEnd) =>
       ByteRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, DicomBytes bytes]) =>
       ByteItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element fromBytes(DicomBytes bytes, Dataset ds, {bool isEvr}) =>
      ByteElement.fromBytes(bytes, ds, isEvr: isEvr);

  Element maybeUndefinedFromBytes(
          DicomBytes bytes,  Dataset ds) =>
      ByteElement.makeMaybeUndefinedFromBytes(bytes, ds);

  Element pixelDataFromBytes(DicomBytes bytes,
          [TransferSyntax ts, VFFragmentList vf]) =>
      ByteElement.pixelDataFromBytes(bytes, ts, vf, cds);

  Element sqFromBytes(Dataset parent,
          [Iterable<Item> items, DicomBytes bytes]) =>
      SQbytes.fromBytes(parent, items, bytes);

  Element fromValues<V>(int code, int vrIndex, List<V> vList) =>
      ByteElement.fromValues(code, vrIndex, vList, isEvr: true, ds: cds);
}
