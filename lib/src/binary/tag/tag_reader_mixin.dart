// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/tag_dataset.dart';
import 'package:element/tag_element.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader_base.dart';

abstract class TagReaderMixin implements DcmReaderBase {
  @override
  Dataset cds;

  @override
  ElementList get elements => cds.elements;

  @override
  Element makeElement(int code, int vrIndex, EBytes eb) =>
      TagElement.fromEB(eb, vrIndex);

  @override
  Element makePixelData(int code, int vrIndex, EBytes eb, {VFFragments fragments}) =>
      TagElement.fromEB(eb, vrIndex);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, EBytes eb, Dataset parent, List<Item> items) =>
      new SQtag.fromBytes(eb, parent, items);

  @override
  RootDataset makeRootDataset(ByteData bd, [ElementList elements, String path]) =>
      new RootDatasetTag(bd: bd, path: path);

  /// Returns a new [Item].
  @override
  Item makeItem(Dataset parent, {ByteData bd, ElementList elements, SQ sequence}) =>
      new ItemTag(parent, bd);
}
