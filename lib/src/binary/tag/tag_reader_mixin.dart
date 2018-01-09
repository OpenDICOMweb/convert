// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/tag_dataset.dart';
import 'package:element/bd_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader_base.dart';

abstract class TagReaderMixin implements DcmReaderBase<int> {
  @override
  Dataset cds;

  @override
  ElementList get elements => cds.elements;

  @override
  Element makeBDElement(int code, int vrIndex, ByteData bd) =>
      TagElement.fromBD(BDElement.make(code, vrIndex, bd), vrIndex);

  @override
  Element makePixelData(int code, int vrIndex, BDElement bd,
      [TransferSyntax ts, VFFragments fragments]) =>
      TagElement.fromEB(bd, vrIndex);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, ByteData bd, Dataset parent, List<Item> items) {

  }
      new SQtag.fromBytes(bd, parent, items);

  @override
  RootDataset makeRootDataset(ByteData bd, [ElementList elements, String path]) =>
      new TagRootDataset(bd: bd, path: path);

  /// Returns a new [Item].
  @override
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new ItemTag(parent, bd);
}
