// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';


/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
typedef Element ElementMaker<V>(ByteData bd);

typedef Element SequenceMaker<V>(
    ByteData bd, Dataset parent, List<Dataset> items);

typedef Element PixelDataMaker<V>(
    ByteData bd, Dataset parent, List<Dataset> items);

const shortFileThreshold = 1024;

abstract class DcmConverterBase {
  /// The [ByteData] being read.
  ByteData get bd;

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

}
