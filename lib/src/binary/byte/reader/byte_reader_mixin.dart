//  Copyright (c) 2016, 2017, 2018, 
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

abstract class ByteReaderMixin {
  RootDataset get rds;
  ReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          Bytes bytes, int fmiEnd) =>
      new ByteRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, Bytes bytes]) =>
      new ByteItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Tag tag, Dataset parent, Iterable items, int vfOffset,
      [int vfLengthField, Bytes bytes]) =>
      unsupportedError();
}

abstract class EvrByteReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  ReadBuffer get rb;

  ByteElement makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      ByteElement.makeFromBytes(bytes, cds);

  Element makeFromValues(int code, Iterable values, int vrIndex, [Bytes bd]) =>
      unsupportedError();

  Element makeFromList(int code, int vrIndex, Iterable values) =>
      TagElement.makeFromCode(code, values, vrIndex, rds);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(
          int code, Dataset parent, Iterable items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      ByteElement.makeSequence(code, parent, items, bytes, rds);
}

abstract class IvrByteReaderMixin {
  RootDataset get rds;
  RootDataset get cds;
  ReadBuffer get rb;

  ByteElement makeFromBytes(int code, Bytes bytes, int vrIndex, int vfOffset) =>
      ByteElement.makeFromBytes(bytes, cds);

  Element makeFromValues(int code, Iterable values, int vrIndex, [Bytes bd]) =>
      unsupportedError();

  ByteElement makeFromList<V>(int code, int vrIndex, Iterable values) =>
      ByteElement.makeFromValues<V>(values, cds);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromCode(
          int code, Dataset parent, Iterable items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      ByteElement.makeSequenceFromBytes(parent, items, bytes);

  /// Returns a new Sequence ([SQ]).
  SQ makeSequenceFromTag(Tag tag, Dataset parent, Iterable items, int vfOffset,
          [int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequenceFromTag(parent, tag, items, vfLengthField, bytes);
}
