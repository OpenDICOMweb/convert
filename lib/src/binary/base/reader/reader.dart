//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/subreader.dart';
import 'package:convert/src/decoding_parameters.dart';
import 'package:convert/src/element_offsets.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/parse_info.dart';

/// Creates a new [Reader], which is a decoder for Binary DICOM
/// (application/dicom).
abstract class Reader {
  final File file;
  final Bytes bytes;

  int fmiEnd = -1;

  /// Creates a new [Reader].
  Reader(this.bytes) : file = null;

  Reader.fromUint8List(Uint8List list, [int offset = 0, int length, Endian
  endian])
      : file = null,
        bytes = new Bytes.typedDataView(list, offset,
      length ?? list.length, endian ?? Endian.host);

  Reader.fromFile(this.file,
      {Endian endian = Endian.little, bool doAsync = false})
      : bytes = Bytes.fromFile(file, endian: endian, doAsync: doAsync);

  // **** Interface
  EvrSubReader get evrSubReader;
  IvrSubReader get ivrSubReader;
  // **** End Interface

  String get path => file.path;
  ReadBuffer get rb => evrSubReader.rb;
  Bytes get input => rb.view();

  DecodingParameters get dParams => evrSubReader.dParams;

  ByteRootDataset get rds => _rds ??= evrSubReader.rds;
  RootDataset _rds;

  Bytes get bytesRead => rb.view(0, rb.index);
  ElementOffsets get offsets => evrSubReader.offsets;
  ParseInfo get pInfo => evrSubReader.pInfo;

  /// Reads a [RootDataset] from _this_. The FMI, if any, MUST already be read.
  RootDataset readRootDataset() {
    if (evrSubReader.doLogging) {
      log
        ..debug('Logging ...')
        ..debug('>R@${rb.index} readRootDataset  ${rb.length} bytes');
    }

    int fmiEnd;
    try {
       fmiEnd = evrSubReader.readFmi();
    } on EndOfDataError catch(e){
      log.warn(e);
    } on ShortFileError catch(e) {
      log.warn(e);
      // ignore: Avoid_catches_without_on_clauses
    } catch(e) {
      log.error(e);
      if (throwOnError) rethrow;
    }

    _rds = evrSubReader.rds;
    (evrSubReader.ts.isEvr)
        ? evrSubReader.readRootDataset(fmiEnd)
        : ivrSubReader.readRootDataset(fmiEnd);
    return _rds;
  }
}
