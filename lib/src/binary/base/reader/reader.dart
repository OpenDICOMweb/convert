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
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/parse_info.dart';

/// Creates a new [Reader], which is a decoder for Binary DICOM
/// (application/dicom).
abstract class Reader {
  final File file;
  final Bytes bytes;

  int fmiEnd = -1;

  /// Creates a new [Reader].
  Reader(this.bytes) : file = null;

  Reader.fromUint8List(Uint8List list, Endian endian)
      : file = null,
        bytes = new Bytes.fromTypedData(list, endian);

  Reader.fromFile(this.file,
      {Endian endian = Endian.little, bool doAsync = false})
      : bytes = Bytes.fromFile(file, endian: endian, doAsync: doAsync);

  // **** Interface
  EvrSubReader get evrSubReader;
  IvrSubReader get ivrSubReader;
  // **** End Interface

  String get path => file.path;
  ReadBuffer get rb => evrSubReader.rb;
  Bytes get input => rb.asBytes();

  DecodingParameters get dParams => evrSubReader.dParams;

  BDRootDataset get rds => _rds ??= evrSubReader.rds;
  RootDataset _rds;

  Bytes get bytesRead => rb.asBytes(0, rb.index);
  ElementOffsets get offsets => evrSubReader.offsets;
  ParseInfo get pInfo => evrSubReader.pInfo;

  /// Reads a [RootDataset] from _this_. The FMI, if any, MUST already be read.
  RootDataset readRootDataset() {
    if (evrSubReader.doLogging) {
      log
        ..debug('Logging ...')
        ..debug('>R@${rb.index} readRootDataset  ${rb.length} bytes');
    }
    final fmiEnd = evrSubReader.readFmi();
    final rds0 = (evrSubReader.rds.transferSyntax.isEvr)
        ? evrSubReader.readRootDataset(fmiEnd)
        : ivrSubReader.readRootDataset(fmiEnd);
    log.debug('${bytesRead.length} bytes read');
    if (evrSubReader.doLogging) {
      log.debug('${evrSubReader.count} Evr Elements read');
      if (ivrSubReader != null) {
        log.debug('${ivrSubReader.count} Ivr Elements read');
      }
    }
    return rds0;
  }
}

