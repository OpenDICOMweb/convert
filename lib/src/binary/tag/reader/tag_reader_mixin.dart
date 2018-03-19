// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/dcm_reader_base.dart';

abstract class TagReaderMixin implements DcmReaderBase {
  @override
  RootDataset get rds;
  @override
  Dataset get cds;
  @override
  Iterable<Element> get elements => cds.elements;

  Element makeElementFromBytes(int code, BDElement be, int vrIndex) =>
      TagElement.makeFromBytes(code, be.vfBytes, vrIndex);

  Element makeTagPixelData(int code, Bytes bd, int vrIndex,
          [int vfLengthField, TransferSyntax ts, VFFragments fragments]) =>
      TagElement.makePixelDataFromBytes(
          code, bd, vrIndex, vfLengthField, ts, fragments);

  SQ makeTagSequence(int code, Dataset parent, List<Item> items, int vrIndex,
          [int vfLengthField, Bytes bytes]) =>
      TagElement.makeSequence(code, parent, items, vfLengthField, bytes);

  RootDataset makeTagRootDataset(Bytes bytes, int fmiEnd, String path) =>
      new TagRootDataset.empty(path, bytes, fmiEnd);

  RootDataset makeRootDatasetFromBD(Bytes bytes, int fmiEnd,
          [String path = '']) =>
      new TagRootDataset.empty(path, bytes, fmiEnd);

  /// Returns a new [Item].
  TagItem makeTagItem(Dataset parent,
          {SQ sequence, List<Element> elements, Bytes bd}) =>
      new TagItem.empty(parent, sequence, bd);
}
