// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_reader/subreader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/parse_info.dart';

/// Creates a new [Reader], which is a decoder for Binary DICOM
/// (application/dicom).
abstract class Reader {
  final Bytes bytes;
  int fmiEnd;

  /// Creates a new [Reader].
  Reader(this.bytes);

  Reader.fromFile(File f) : bytes = f.readAsBytesSync();

  Reader.fromPath(String path) : bytes = new File(path).readAsBytesSync();

  // **** Interface
  EvrSubReader get evrSubReader;
  IvrSubReader get ivrSubReader;
  // **** End Interface

  ReadBuffer get rb => evrSubReader.rb;
  DecodingParameters get dParams => evrSubReader.dParams;
  BDRootDataset get rds => evrSubReader.rds;
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
    if (evrSubReader.doLogging) {
      log.debug('${evrSubReader.count} Evr Elements read');
      if (ivrSubReader != null)
        log.debug('${ivrSubReader.count} Ivr Elements read');
    }
    return rds0;
  }
}

/* TODO: later
  static Future<Uint8List> _readAsync(File file) async =>
      await file.readAsBytes();
*/
