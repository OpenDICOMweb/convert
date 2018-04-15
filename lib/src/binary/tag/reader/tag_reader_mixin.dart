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
  ReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          Bytes bytes, int fmiEnd) =>
      new BDRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, Bytes bytes]) =>
      new BDItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      TagElement.makeFromBytes(code, bytes, vrIndex, vfOffset);

  Element makeFromValues(int code, List values, int vrIndex, [Bytes bd]) =>
      unsupportedError();

  Element makeFromList(int code, int vrIndex, Iterable values) =>
      TagElement.makeFromCode(code, values, vrIndex);

  Element makePixelData(int code, Bytes bytes, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      TagElement.makePixelData(
          code, bytes, vrIndex, vfLengthField, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(int code, Dataset parent, Iterable items,
          [int vfOffset, int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequenceFromCode(
          code, parent, items, vfLengthField, bytes);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Tag tag, Dataset parent, Iterable items,
          [int vfOffset, int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequenceFromTag(tag, parent, items, vfLengthField, bytes);
}
