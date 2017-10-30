// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:element/byte_element.dart';
import 'package:dataset/byte_dataset.dart';

/// The type of the different Value Field readers.  Each [ElementMaker]
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

/*
  ElementMaker get makeElement;
  SequenceMaker get makeSequence;
  ItemMaker get makeItem;
*/


/*
  /// Returns a new Element.
  Element makeElement(EBytes eb, int vrIndex, [VFFragments fragments]);

  /// Returns a new Sequence.
  /// [eb] is the complete [EBytes] for the Sequence.
  SQ makeSequence(EBytes eb, Dataset parent, List<Item> items);

  /// Returns a new [RootDataset].
  /// [dsbytes] is the complete [DSBytes] for the [RootDataset].
  RootDataset makeRootDataset(RDSBytes dsbytes, Dataset parent, ElementList elements);

  /// Returns a new [Item].
  Item makeItem(Dataset parent, {ElementList elements, SQ sequence, DSBytes eb});
*/

  /// Returns a new [Item].
//  Item makeItemFromBytes(IDSBytes dsBytes, Dataset parent, ElementList elements,
//      [SQ sequence]);

  /// Returns a subtype of [Element].
 // Element makePixelData(EBytes eb, int vrIndex, [VFFragments fragments]);

  /// Interface for logging
  String itemInfo(Item item);

  /// Interface for logging
  String elementInfo(Element e);

}
