// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';

import 'package:dcm_convert/src/binary/base/reader/dcm_reader_base.dart';

abstract class ByteReaderMixin implements DcmReaderBase {
  @override
  Dataset cds;

  @override
  ElementList get elements => cds.elements;

  @override
  Element makeElement(int code, int vrIndex, EBytes eb) => makeBEFromEBytes(eb, vrIndex);

  @override
  Element makePixelData(int code, int vrIndex, EBytes eb, {VFFragments fragments}) =>
      makeBEPixelDataFromEBytes(eb, vrIndex);

  /// Returns a new Sequence ([SQ]).
  @override
  SQ makeSequence(int code, EBytes eb, Dataset parent, List<Item> items) =>
      new SQbyte.fromBytes(eb, parent, items);

  @override
  RootDataset makeRootDataset(RDSBytes dsBytes, [ElementList elements, String path]) =>
      new RootDatasetByte(dsBytes, elements: elements, path: path);

  /// Returns a new [ItemByte].
  @override
  Item makeItem(Dataset parent, {IDSBytes eb, ElementList elements, SQ sequence}) =>
      new ItemByte(parent, eb);
}
