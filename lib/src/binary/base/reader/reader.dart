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

    try {
      final fmiEnd = evrSubReader.readFmi();
      final ts = evrSubReader.rds.transferSyntax;
      _rds = (ts.isEvr)
          ? evrSubReader.readRootDataset(fmiEnd, ts)
          : ivrSubReader.readRootDataset(fmiEnd, ts);
    } on EndOfDataError catch (e) {
      print(e);
      if (throwOnError) rethrow;
      return _rds = null;
    } on InvalidTransferSyntax catch (e) {
      print(e);
      if (throwOnError) rethrow;
      return _rds = null;
    } on DataAfterPixelDataError catch (e) {
      print(e);
      return _rds;
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      print(e);
      if (throwOnError) rethrow;
      return _rds = null;
    }
    log.debug('Bytes read: ${bytesRead.length} ');
    if (evrSubReader.doLogging) {
      log.debug('Evr Elements: ${evrSubReader.count} ');
      if (ivrSubReader != null && ivrSubReader.count != 0) {
        log.debug('Ivr Elements: ${ivrSubReader.count} ');
      }
    }
    return _rds;
  }
}
