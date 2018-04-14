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

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Tag tag, Dataset parent, Iterable items, int vfOffset,
      [int vfLengthField, Bytes bytes]) =>
      unsupportedError();
}

abstract class EvrByteReaderMixin {
  RootDataset get rds;
  ReadBuffer get rb;

  Element makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      EvrElement.makeFromBytes(code, bytes, vrIndex);

  Element makeFromValues(int code, Iterable values, int vrIndex, [Bytes bd]) =>
      unsupportedError();

  Element makeFromList(int code, int vrIndex, Iterable values) =>
      TagElement.makeFromCode(code, values, vrIndex);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(
          int code, Dataset parent, Iterable items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      EvrElement.makeSequence(code, parent, items, bytes);
}

abstract class IvrByteReaderMixin {
  RootDataset get rds;
  ReadBuffer get rb;

  Element makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      IvrElement.makeFromBytes(code, bytes, vrIndex);

  Element makeFromValues(int code, Iterable values, int vrIndex, [Bytes bd]) =>
      unsupportedError();

  Element makeFromList(int code, int vrIndex, Iterable values) =>
      TagElement.makeFromCode(code, values, vrIndex);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(
          int code, Dataset parent, Iterable items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      IvrElement.makeSequenceFromCode(code, parent, items, bytes);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Tag tag, Dataset parent, Iterable items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      IvrElement.makeSequenceFromTag(tag, parent, items, bytes);
}
