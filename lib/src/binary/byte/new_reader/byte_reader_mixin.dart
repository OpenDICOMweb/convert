// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

abstract class ByteReaderMixin {
  RootDataset get rds;
  ReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          Bytes bytes, int fmiEnd) =>
      new BDRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, Bytes bytes]) =>
      new BDItem(parent, sequence, eMap ?? <int, Element>{}, bytes);
}

abstract class EvrByteReaderMixin {
  RootDataset get rds;
  ReadBuffer get rb;

  Element makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      EvrElement.makeFromBytes(code, bytes, vrIndex);

  Element makeFromValues<V>(int code, List<V> values, int vrIndex,
          [Bytes bd]) =>
      unsupportedError();

  Element makeFromList(int code, int vrIndex, Iterable values) =>
      TagElement.makeFromCode(code, values, vrIndex);

  Element makePixelData(int code, Bytes bytes, int vrIndex, int vfOffset,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      EvrElement.makePixelData(code, bytes, vrIndex, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequence(int code, Dataset parent, Iterable<Item> items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      EvrElement.makeSequence(code, parent, items, bytes);
}

abstract class IvrByteReaderMixin {
  RootDataset get rds;
  ReadBuffer get rb;

  Element makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      IvrElement.makeFromBytes(code, bytes, vrIndex);

  Element makeFromValues<V>(int code, List<V> values, int vrIndex,
          [Bytes bd]) =>
      unsupportedError();

  Element makeFromList(int code, int vrIndex, Iterable values) =>
      TagElement.makeFromCode(code, values, vrIndex);

  Element makePixelData(int code, Bytes bytes, int vrIndex, int vfOffset,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      IvrElement.makePixelData(code, bytes, vrIndex, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequence(int code, Dataset parent, Iterable<Item> items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      IvrElement.makeSequence(code, parent, items, bytes);
}
