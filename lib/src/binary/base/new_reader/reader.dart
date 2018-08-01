//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:converter/src/binary/base/new_reader/subreader.dart';
import 'package:converter/src/decoding_parameters.dart';
import 'package:converter/src/element_offsets.dart';
import 'package:converter/src/parse_info.dart';

/// Creates a new [Reader], which is a decoder for Binary DICOM
/// (application/dicom).
abstract class Reader {
  /// The bytes being read.
  Bytes _bytes;

  int fmiEnd = -1;
  bool success = false;
  String status = 'Not Read';

  /// Creates a new [Reader].
  Reader(this._bytes);

  Reader.fromUint8List(Uint8List list,
      [int offset = 0, int length, Endian endian])
      : _bytes = new Bytes.typedDataView(
            list, offset, length ?? list.length, endian ?? Endian.host);

  // **** Interface
  EvrSubReader get evrSubReader;
  IvrSubReader get ivrSubReader;
  // **** End Interface

  Bytes get bytes => _bytes;
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
    status = 'Reading ...';
    if (evrSubReader.doLogging)
      log.debug('>R@${rb.index} readRootDataset  ${rb.length} bytes');

    final fmiEnd = evrSubReader.readFmi();

    final ts = evrSubReader.rds.transferSyntax;
    final root = (ts.isEvr)
        ? evrSubReader.readRootDataset(fmiEnd, ts)
        : ivrSubReader.readRootDataset(fmiEnd, ts);

    log.debug('${bytesRead.length} bytes read');
    if (evrSubReader.doLogging) {
      log.debug('${evrSubReader.count} Evr Elements read');
      if (ivrSubReader != null) {
        log.debug('${ivrSubReader.count} Ivr Elements read');
      }
    }
    if (rds == null) {
      success = false;
      status = 'Encountered errors';
    } else {
      success = true;
      status = 'Finished reading successfully';
    }
    return root;
  }
}
