// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:element/byte_element.dart';
import 'package:dataset/byte_dataset.dart';

import 'package:dcm_convert/src/element_offsets.dart';

/// The Types of the different Value Field readers.  Each [ElementMaker]
/// reads the Value Field for a particular Value Representation.
typedef Element ElementMaker(EBytes eb, int vrIndex, [VFFragments fragments]);
typedef SQ SequenceMaker(EBytes eb, Dataset parent, List<Item>items);
typedef Item ItemMaker(Dataset parent);
typedef Element PixelDataMaker<V>(EBytes eb, int vrIndex, [VFFragments fragments]);

const int shortFileThreshold = 1024;

abstract class DcmReaderInterface {
  /// Returns the [ByteData] for the entire Root [Dataset].
  ByteData get rootBD;

  /// Returns the Root [Dataset].
  RootDataset get rootDS;

  /// The current dataset.  This changes as Sequences are read.
  Dataset get currentDS;

  /// The current [Element] [Map].
  List<Element> get elements => currentDS.elements;

  /// The current duplicate [List<Element>].
  List<Element> get duplicates => currentDS.elements.duplicates;

  ElementOffsets get offsets;

  /// Interface for logging
  String itemInfo(Item item);

  /// Interface for logging
  String elementInfo(Element e);

}
