// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/parse_info.dart';

abstract class LoggingEvrSubReader extends EvrSubReader with LoggingReaderMixin {
  @override
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  LoggingEvrSubReader(DecodingParameters dParams, RootDataset rds)
      : offsets = new ElementOffsets(),
        pInfo = new ParseInfo(rds),
        super(dParams, rds);
}

abstract class LoggingIvrSubReader extends IvrSubReader with LoggingReaderMixin {
  @override
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  LoggingIvrSubReader(DecodingParameters dParams, RootDataset rds)
      : offsets = new ElementOffsets(),
        pInfo = new ParseInfo(rds),
        super(dParams, rds);
}

abstract class LoggingReaderMixin {
  SubReader get subreader;
  ReadBuffer get rb;
  ElementOffsets get offsets;
  ParseInfo get pInfo;

  RootDataset readRootDataset([int fmiEnd]) {
    log.debug('$_start readRootDataset: fmiEnd($fmiEnd)');
    final rds = subreader.readRootDataset(fmiEnd);
    log..debug('$_end readRootDataset: $rds')..debug('${rds.summary}');
    return rds;
  }

  Item readItem([SQ sq]) {
    log.debug('$_start readItem: $sq');
    final item =  subreader.readItem(sq);
    log.debug('$_end readItem: $item');
    pInfo.addItem(sq, item);
    return item;
  }

  Element readShortElement(int code, int eStart, int vrIndex) {
    log.debug(_startRead(code, eStart, vrIndex, 'readShort'));
    final e =  subreader.readShortElement(code, eStart, vrIndex);
    pInfo.addElement(e);
    log.debug(_endRead(e, 'readShort'));
    return e;
  }

  Element readLongElement(int code, int eStart, int vrIndex) {
    log.debug(_startRead(code, eStart, vrIndex, 'readLong'));
    final e =  subreader.readShortElement(code, eStart, vrIndex);
    log.debug(_endRead(e, 'readLong'));
    pInfo.addElement(e);
    return e;
  }

  Element readMaybeUndefinedElement(int code, int eStart, int vrIndex) {
    log.debug(_startRead(code, eStart, vrIndex, 'readMaybeUndefined'));
    final e =  subreader.readShortElement(code, eStart, vrIndex);
    log.debug(_endRead(e, 'readMaybeUndefined'));
    pInfo.addElement(e);
    return e;
  }

  SQ readSequence(int code, int eStart, int vrIndex) {
    log.debug(_startRead(code, eStart, vrIndex, 'readSQ'));
    final e =  subreader.readSequence(code, eStart, vrIndex);
    log.debug(_endRead(e, 'readSQ'));
    pInfo.addSequence(e);
    return e;
  }


// **** Internals
  String get _index => '${rb.index}'.padLeft(5, '0');

  String get _start => '>R@$_index';

  String get _end => '<R@$_index';

  String atIndex(int index) => '@$index';

  String _startRead(int code, int eStart, int vrIndex, String id) =>
      '$_start $id: ${dcm(code)} ${vrIdByIndex[vrIndex]} ${atIndex(eStart)}';

  String _endRead(Element e, String id) => '$_end $id: $e';
}
