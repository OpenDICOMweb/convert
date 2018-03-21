// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

abstract class ByteReaderMixin {
  RootDataset get rds;
//  @override
//  Dataset get cds;
//  @override
//  Iterable<Element> get elements => cds.elements;


  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
      Bytes bd, int fmiEnd) =>
      new BDRootDataset(fmi, eMap, path, bd, fmiEnd);

  Item makeItem(Dataset parent,
      [SQ sequence, Map<int, Element> eMap, Bytes bd]) =>
      new BDItem(parent, sequence, eMap ?? <int, Element>{}, bd);

  BDElement makeFromBytes(int code, Bytes bd, int vrIndex) =>
      EvrElement.make(code, bd, vrIndex);

  BDElement makeFromValues<V>(int code, List<V> values, int vrIndex,
          [Bytes bd]) =>
      unsupportedError();

  Element makeElementFromList(int code, int vrIndex, Iterable values) {
    final tag = Tag.lookupByCode(code, vrIndex, values);
    return TagElement.make(tag, values, vrIndex);
  }

  BDElement makePixelData(int code, Bytes bd, int vrIndex,
          [TransferSyntax ts, VFFragments fragments]) =>
      EvrElement.makePixelData(code, bd, vrIndex, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequence(int code, Dataset parent, Iterable<Item> items, [Bytes bd]) =>
      EvrElement.makeSequence(code, parent, items, bd);
}
