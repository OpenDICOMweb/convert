// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/parse_info.dart';

abstract class LoggingEvrSubReader extends LoggingSubReader
    implements EvrSubReader {
  LoggingEvrSubReader() : super();

  // **** Interface
  @override
  EvrSubReader get subReader;
  // **** End Interface

  @override
  int readFmi() => subReader.readFmi();
}

abstract class LoggingIvrSubReader extends LoggingSubReader
    implements IvrSubReader {
  LoggingIvrSubReader() : super();

  // **** Interface
  @override
  IvrSubReader get subReader;

  @override
  bool get doLookupVRIndex => subReader.doLookupVRIndex;
}

abstract class LoggingSubReader implements SubReader {
  @override
  final ElementOffsets offsets;
  @override
  final ParseInfo pInfo;

  LoggingSubReader([RootDataset rds])
      : offsets = new ElementOffsets(),
        pInfo = new ParseInfo(rds);

  // **** Interface
  SubReader get subReader;
  // **** End Interface

  @override
  Bytes get bytes => subReader.bytes;

  @override
  final String kItem32BitLEAsString = hex32(kItem32BitLE);
  @override
  bool get isEvr => subReader.isEvr;
  @override
  ReadBuffer get rb => subReader.rb;
  @override
  RootDataset get rds => subReader.rds;
  @override
  Dataset get cds => subReader.cds;
  @override
  set cds(Dataset ds) => cds = ds;
  @override
  DecodingParameters get dParams => subReader.dParams;
  @override
  TransferSyntax get defaultTS => subReader.defaultTS;
  @override
  int get count => subReader.count;
  @override
  bool get doLogging => subReader.doLogging;
  /// The current [Element] [Map].
  @override
  Iterable<Element> get elements => cds.elements;

  /// The current duplicate [List<Element>].
  @override
  Iterable<Element> get duplicates => cds.history.duplicates;

  @override
  bool get isReadable => rb.isReadable;
  @override
  Uint8List get rootBytes => rb.asUint8List(rb.offsetInBytes, rb.lengthInBytes);
  @override
  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  @override
  RootDataset readRootDataset([int fmiEnd]) {
    print('LogLevel: ${log.level}');
    log.debug('$_start readRootDataset: fmiEnd($fmiEnd)', 1);
    final rds = subReader.readRootDataset(fmiEnd);
    log..debug('$_end readRootDataset: $rds', -1)..debug('${rds.summary}');
    return rds;
  }

  @override
  void readDatasetDefinedLength(Dataset ds, int dsStart, int remaining) {
    log.debug('$_start readDatasetDefinedLength: '
        '$ds start($dsStart) remaining($remaining', 1);
    subReader.readDatasetDefinedLength(ds, dsStart, rb.rRemaining);
    log.debug('$_end readRootDataset: $ds', -1);
  }

  @override
  void readDatasetUndefinedLength(Dataset ds, int dsStart) {
    log.debug('$_start readDatasetUndefinedLength: $ds start($dsStart)', 1);
    subReader.readDatasetUndefinedLength(ds, dsStart);
    log.debug('$_end readDatasetUndefinedLength: $ds', -1);
  }

  @override
  Item readItem([SQ sq]) {
    log.debug('$_start readItem: $sq');
    final item = subReader.readItem(sq);
    log.debug('$_end readItem: $item');
    pInfo.addItem(sq, item);
    return item;
  }

  @override
  Element readElement() => subReader.readElement();

/*
  @override
  Element readLongElement(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    log.debug(_startRead(code, eStart, vrIndex, 'readLong'));
    final e = subReader.readLongElement(code, eStart, vrIndex, vfOffset, vlf);
    log.debug(_endRead(e, 'readLong'));
    pInfo.addElement(e);
    return e;
  }
*/

/*
  @override
  Element readMaybeUndefinedElement(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    log.debug(_startRead(code, eStart, vrIndex, 'readMaybeUndefined'));
    final e = subReader.readMaybeUndefinedElement(code, eStart, vrIndex, vfOffset, vlf);
    log.debug(_endRead(e, 'readMaybeUndefined'));
    pInfo.addElement(e);
    return e;
  }
*/

  @override
  SQ readSequence(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    log.debug(_startRead(code, eStart, vrIndex, 'readSQ'));
    final e = subReader.readSequence(code, eStart, vrIndex, vfOffset, vlf);
    log.debug(_endRead(e, 'readSQ'));
    pInfo.addSequence(e);
    return e;
  }

// **** Internals
  String get _index => '${subReader.rb.index}'.padLeft(5, '0');

  String get _start => '>R@$_index';

  String get _end => '<R@$_index';

  String atIndex(int index) => '@$index';

  String _startRead(int code, int eStart, int vrIndex, String id) =>
      '$_start $id: ${dcm(code)} ${vrIdByIndex[vrIndex]} ${atIndex(eStart)}';

  String _endRead(Element e, String id) => '$_end $id: $e';
}
