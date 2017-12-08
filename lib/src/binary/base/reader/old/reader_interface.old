// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:element/byte_element.dart';
import 'package:uid/uid.dart';

typedef Element EReader();
typedef Element EMaker(EBytes eb, int vrIndex);
typedef Element PDMaker(EBytes eb, int vrIndex,
    [TransferSyntax ts, VFFragments fragments]);
typedef SQ SQMaker(EBytes eb, Dataset parent, List<Item> items);
typedef Item ItemMaker(Dataset parent);

/// The Types of the different Value Field readers.  Each [EMaker]
/// reads the Value Field for a particular Value Representation.

abstract class DcmReaderInterface {
  /// Returns the [ByteData] for the entire Root [Dataset].
  ReadBuffer get rb;

  /// Returns the Root [Dataset].
  RootDataset get rds;

  /// The current dataset.  This changes as Sequences are read.
  Dataset get cds;

  /// The current [Element] [Map].
  List<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  List<Element> get duplicates => cds.elements.duplicates;

  ByteData readFmi();

  Item readItem();
  // ByteData readRootDataset();

  RootDataset read();

  Element readElement();

  Element readDefinedLength(int code, int eStart, int vrIndex, int vlf);

  Element readMaybeUndefinedLength(int code, int eStart, int vrIndex, int vlf);

  Element readSequence(int code, int eStart, int vrIndex);

  // The methods below are prototypes for supplying
  void readStartMsg(int eStart, int vrIndex, int code, String name, int vlf) {}

  void readEndMsg(String name, Dataset ds) {}

  /// Log the start of reading an element;
  void logEReadStart(int eStart, int vrIndex, int code, String name, int vlf) {}

  void logEEnd(int eStart, Element e) {}
}
