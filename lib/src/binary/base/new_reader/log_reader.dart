// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/reader.dart';

/*
class LoggingEvrReader extends EvrReader {

}
*/

abstract class LoggingReader {
  Reader reader;
  
 // LoggingReader(this.reader);

  ReadBuffer get rb => reader.rb;
  
  String get index => '${rb.index}'.padLeft(5, '0');

  String get start => '>R@$index';

  String get end => '<R@$index';
  
  String atIndex(int index) => '@$index';

  RootDataset readRootDataset([int fmiEnd]) {
    log.debug('$start readRootDataset: fmiEnd($fmiEnd)');
    final rds = reader.readRootDataset(fmiEnd);
    log..debug('$end readRootDataset: $rds')..debug('${rds.summary}');
    return rds;
  }

  Item readItem([SQ sq]) {
    log.debug('$start readItem: $sq');
    final item = reader.readItem(sq);
    log.debug('$end readItem: $item');
    return item;
  }

  String startRead(int code, int eStart, int vrIndex, String id) =>
      '$start $id: ${dcm(code)} ${vrIdByIndex[vrIndex]} ${atIndex(eStart)}';

  String endRead(Element e, String id) => '$end $id: $e';

  Element readShortElement(int code, int eStart, int vrIndex) {
    log.debug(startRead(code, eStart, vrIndex, 'readShort'));
    final e = reader.readShortElement(code, eStart, vrIndex);
    log.debug(endRead(e, 'readShort'));
    return e;
  }

  Element readLongElement(int code, int eStart, int vrIndex) {
    log.debug(startRead(code, eStart, vrIndex, 'readLong'));
    final e = reader.readShortElement(code, eStart, vrIndex);
    log.debug(endRead(e, 'readLong'));
    return e;
  }

  Element readMaybeUndefinedElement(int code, int eStart, int vrIndex) {
    log.debug(startRead(code, eStart, vrIndex, 'readMaybeUndefined'));
    final e = reader.readShortElement(code, eStart, vrIndex);
    log.debug(endRead(e, 'readMaybeUndefined'));
    return e;
  }

  SQ readSequence(int code, int eStart, int vrIndex) {
    log.debug(startRead(code, eStart, vrIndex, 'readSQ'));
    final e = reader.readSequence(code, eStart, vrIndex);
    log.debug(endRead(e, 'readSQ'));
    return e;
  }
}
