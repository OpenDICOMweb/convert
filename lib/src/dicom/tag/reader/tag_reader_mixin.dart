// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/dicom/base/reader/dcm_reader_base.dart';

abstract class TagReaderMixin implements DcmReaderBase<int> {
  @override
  RootDataset get rds;
  @override
  Dataset get cds;

  Element makeTagElement(int code, int vrIndex, BDElement bd) =>
      TagElement.make(bd.tag, bd.values, vrIndex);

  Element makeTagPixelData(int code, int vrIndex, BDElement bd,
          [TransferSyntax ts, VFFragments fragments]) =>
      null;

  SQ makeTagSequence(
          int code, BDElement bd, Dataset parent, List<Item> items) =>
      null;

  RootDataset makeTagRootDataset(String path, ByteData bd, int fmiEnd) =>
      new TagRootDataset.empty(path, bd, fmiEnd);

  RootDataset makeTagRootDatasetFromBD(ByteData bd, int fmiEnd, String path) =>
      new TagRootDataset.empty(path, bd, fmiEnd);

  /// Returns a new [Item].
  TagItem makeTagItem(Dataset parent,
          {ByteData bd, Map<int, Element> elements, SQ sequence}) =>
      new TagItem.empty(parent, sequence, bd);
}
