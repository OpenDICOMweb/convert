// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/tag_dataset.dart';
import 'package:element/bd_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader_base.dart';


abstract class TagReaderMixin implements DcmReaderBase<int> {
  @override
  RootDataset get rds;
  @override
  Dataset get cds;

  @override
  Element makeTagElement(int code, int vrIndex, BDElement bd) =>
      TagElement.make(bd.tag, vrIndex, bd.values);

  @override
  Element makeTagPixelData(int code, int vrIndex, BDElement bd,
                           [TransferSyntax ts, VFFragments fragments]) {

  }

  @override
  SQ makeTagSequence(int code, BDElement bd, Dataset parent, List<Item> items) {

  }

  @override
  RootDataset makeTagRootDataset(ByteData bd, int fmiEnd, String path) =>
      new TagRootDataset(bd: bd, fmiEnd: fmiEnd, path: path);

  @override
  RootDataset makeTagRootDatasetFromBD(ByteData bd, int fmiEnd, String path) =>
      new TagRootDataset(bd: bd, fmiEnd: fmiEnd, path: path);

  /// Returns a new [Item].
  TagItem makeTagItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new TagItem(parent, bd);
}