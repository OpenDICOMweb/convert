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
  final bool doLogging;
  int fmiEnd;

  /// Creates a new [Reader].
  Reader(this.bytes, {this.doLogging = false});

  Reader.fromFile(File f, {this.doLogging = false})
      : bytes = f.readAsBytesSync();

  Reader.fromPath(String path, {this.doLogging = false})
      : bytes = new File(path).readAsBytesSync();

  EvrSubReader get evrSubReader;
  ReadBuffer get rb => evrSubReader.rb;
  DecodingParameters get dParams => evrSubReader.dParams;
  BDRootDataset get rds => evrSubReader.rds;
  ElementOffsets get offsets => evrSubReader.offsets;
  ParseInfo get pInfo => evrSubReader.pInfo;

  bool isFmiRead = false;
  int readFmi(int eStart) => evrSubReader.readFmi();

  IvrSubReader get ivrSubReader;

  RootDataset readRootDataset([int fmiEnd]) {
    if (!isFmiRead) fmiEnd ??= readFmi(0);
    final rds = (evrSubReader.rds.transferSyntax.isEvr)
        ? evrSubReader.readRootDataset(fmiEnd)
        : ivrSubReader.readRootDataset(fmiEnd);
    print('${evrSubReader.count} Evr Elements read');
    if (ivrSubReader != null) print('${ivrSubReader.count} Ivr Elements read');
    return rds;
  }
}
/* TODO: later
  static Future<Uint8List> _readAsync(File file) async =>
      await file.readAsBytes();
*/
