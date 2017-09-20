// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:tag/tag.dart';


/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
typedef Element ElementMaker<V>(ByteData bd);

typedef Element SequenceMaker<V>(
    ByteData bd, Dataset parent, List<Dataset> items);

typedef Element PixelDataMaker<V>(
    ByteData bd, Dataset parent, List<Dataset> items);

const shortFileThreshold = 1024;

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
  Dataset get rootDS;

  /// The current dataset.  This changes as Sequences are read.
  Dataset get currentDS;
  set currentDS(Dataset ds);

	/// The current [Element] [Map].
  Map<int, Element> get currentMap;
	set currentMap(Map<int, Element> map);

	/// The current duplicate [Element] [Map].
	Map<int, Element> get currentDupMap;
	set currentDupMap(Map<int, Element> map);

  /// Returns an empty [Map], which be a subtype of [Element].
  Map<int, Element> makeEmptyMap();

  /// Returns a subtype of [Element].
  Element makeElement(int vrIndex, Tag tag, ByteData bytes,
                      [int vfLength, Uint8List vfBytes]);

  /// Interface for logging
  String elementInfo(Element e);

  /// Returns a subtype of [Element].
  Element makePixelData(int vrIndex, ByteData bytes,
                        [VFFragments fragments, Tag tag, int vfLength, ByteData vfBytes]);

  /// Returns a new Sequence.
  /// [bd] is the complete [ByteData] for the Sequence.
  Element makeSQ(ByteData bd, Dataset parent, List items, int vfLength, bool isEVR);

  /// Interface to Item constructor.
  Dataset makeItem(ByteData bd, Dataset parent, int vfLength, Map<int, Element> map,
                   [Map<int, Element> dupMap]);

  /// Interface for logging
  String itemInfo(ByteItem item);

}
