// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

abstract class TagReaderMixin {
  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          Bytes bytes, int fmiEnd) =>
      new TagRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, Bytes bytes]) =>
      new TagItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element makeFromBytes(int code, Bytes bytes, int vrIndex) =>
      TagElement.makeFromBytes(code, bytes, vrIndex);

  Element makeFromValues<V>(int code, Iterable<V> values, int vrIndex,
          [Bytes bd]) =>
      TagElement.makeFromValues(code, values, vrIndex);

  Element makeFromList(int code, int vrIndex, Iterable values) {
    final tag = Tag.lookupByCode(code, vrIndex, values);
    return TagElement.make(tag, values, vrIndex);
  }

  Element makePixelData(int code, Bytes bytes, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      TagElement.makePixelData(
          code, bytes, vrIndex, vfLengthField, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequence(int code, Dataset parent, List<Item> items,
          [int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequence(code, parent, items, vfLengthField, bytes);


}
