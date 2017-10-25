// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:element/element.dart';
import 'package:dataset/dataset.dart';
import 'package:tag/tag.dart';

/// The type of the different Value Field readers.  Each [ElementMaker]
/// reads the Value Field for a particular Value Representation.
typedef Element ElementMaker<V>(ByteData bd);

typedef Element SequenceMaker<V>(ByteData bd, Dataset parent, List<Dataset> items);

typedef Element PixelDataMaker<V>(ByteData bd, Dataset parent, List<Dataset> items);

const int shortFileThreshold = 1024;

abstract class DcmReaderInterface {
/*
  /// The [ByteData] being read.
  ByteData bd;

  // Input parameters
  bool get async;
  bool get fast;
  bool get fmiOnly;

  /// If [true] errors will throw; otherwise, return [null].
  bool get throwOnError;

  /// If [true] and [FMI] is not present, abort reading.
  bool get allowMissingFMI;

  /// If [true], then duplicate [Element]s will be stored.
  bool get allowDuplicates;

  /// When reading only data with [targetTS] [TransferSyntax] will
  /// be decoded. When writing the Root Dataset will be encoded
  /// in [targetTS] [TransferSyntax].

  TransferSyntax get targetTS;
*/

  /// Returns the [ByteData] for the entire Root [Dataset].
  ByteData get rootBD;

  /// Returns the Root [Dataset].
  RootDataset get rootDS;

  /// The current dataset.  This changes as Sequences are read.
  Dataset get currentDS;
  set currentDS(Dataset ds);

  /// The current [Element] [Map].
  Map<int, Element> get currentMap;
  set currentMap(Map<int, Element> map);

  /// The current duplicate [Element] [Map].
  Map<int, Element> get currentDupMap;
  set currentDupMap(Map<int, Element> map);

  ElementList get elementList;

  /// Returns an empty [Map], which be a subtype of [Element].
  Map<int, Element> makeEmptyMap();

  /// Returns a subtype of [Element].
  Element makeElement<V>(int index, List<V> values,
      [int vfLengthField, Uint8List vfBytes]);

  /// Returns a subtype of [Element].
  Element makeElementFromBytes(int index, ByteData bytes, int vfLengthField);

  /// Returns a subtype of [Element].
  Element makePixelData(int vrIndex, ByteData bytes,
      [VFFragments fragments, Tag tag, int vfLength, ByteData vfBytes]);

  /// Returns a new Sequence.
  /// [bd] is the complete [ByteData] for the Sequence.
  Element makeSQ(Dataset parent, List items, int vfLength, bool isEVR, [ByteData bd]);

  /// Interface to Item constructor.
  Dataset makeItemFromList(Dataset parent, ElementList eList, int vfLengthField,
      [ByteData bd]);

  /// Interface for logging
  String itemInfo(Item item);

  /// Interface for logging
  String elementInfo(Element e);
}
