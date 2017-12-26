// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:element/byte_element.dart';
import 'package:dataset/byte_dataset.dart';

import 'package:dcm_convert/src/element_offsets.dart';
import 'write_buffer.dart';

const int shortFileThreshold = 1024;

abstract class DcmWriterInterface {
  /// Returns the [ByteData] for the entire Root [Dataset].
  WriteBuffer get wb;

  /// Returns the Root [Dataset].
  RootDataset get rds;

  /// The current dataset.  This changes as Sequences are read.
  Dataset get cds;

  /// The current [Element] [Map].
  List<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  List<Element> get duplicates => cds.elements.duplicates;

  ElementOffsets get inputOffsets;
  ElementOffsets get outputOffsets;

  Uint8List write();

  Uint8List writeFmi();

  /// Interface for logging
  String itemInfo(Item item);

  /// Interface for logging
  String elementInfo(Element e);
}