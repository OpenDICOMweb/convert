// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/dcm_reader_base.dart';

abstract class BDReaderMixin implements DcmReaderBase<int> {
  @override
  RootDataset get rds;
  @override
  Dataset get cds;
  @override
  Iterable<Element> get elements => cds.elements;

  BDElement makeElementFromBD(int code, int vrIndex, ByteData bd) =>
      EvrElement.make(code, vrIndex, bd);

  Element makeElementFromList(int code, int vrIndex, Iterable values) {
    final tag = Tag.lookupByCode(code);
    return TagElement.make(tag, values, vrIndex);
  }

  @override
  BDElement makePixelData(int code, int vrIndex, ByteData bd,
          [TransferSyntax ts, VFFragments fragments]) =>
      EvrElement.makePixelData(code, vrIndex, bd, ts, fragments);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(
          int code, ByteData bd, Dataset parent, Iterable<Item> items) =>
      EvrElement.makeSequence(code, bd, parent, items);

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          ByteData bd, int fmiEnd) =>
      new BDRootDataset(fmi, eMap, path, bd, fmiEnd);

  @override
  Item makeItem(
    Dataset parent,
    Map<int, Element> eMap, [
    SQ sequence,
    ByteData bd,
  ]) =>
      new BDItem(parent, eMap, sequence, bd);
}
