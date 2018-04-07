// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/reader.dart';
import 'package:convert/src/binary/byte/reader/byte_reader.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/utilities/io_utils.dart';

// ignore_for_file: avoid_catches_without_on_clauses

Future<Uint8List> readFileFast(File f, {bool fast = true}) async =>
    (fast) ? await f.readAsBytes() : f.readAsBytesSync();

Future<Uint8List> readFileAsync(File f) async {
  final bytes = await f.readAsBytes();
  print(bytes.length);
  return bytes;
}

Uint8List readFileSync(File f) => f.readAsBytesSync();

ByteReader decodeFileAsBE(File f, ByteReader reader,
    {bool throwOnError = true,
    bool fast = true,
    bool isAsync = true,
    bool showStats = true}) {
  final reader = new ByteReader.fromFile(f);
  return readFile(f, reader);
}

//Urgent make sure garbage is not being retained
//Urgent add async
Reader readFile(File f, Reader reader,
    {bool throwOnError = true,
    bool fast = true,
    bool isAsync = true,
    bool showStats = true}) {
  final pad = ''.padRight(5);
  final cPath = cleanPath(f.path);
  RootDataset rds0;

  try {
    final bytes = readPath(cPath);
    if (bytes == null) return reader;
    final doLogging = system.level > Level.debug;
    final reader0 = new ByteReader.fromBytes(bytes, doLogging: doLogging);

    final rds0 = reader0.readRootDataset();
    if (rds0 == null) return reader;


// TODO: move into dataset.warnings.
    final e = rds0[kPixelData];
    if (e == null) {
      log.info1('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }
    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $cPath');
    if (throwOnError) rethrow;
  } on InvalidTransferSyntax catch (e) {
    log.error(e);
    return reader;
  } catch (e) {
    log.error('Caught $e\n  on File: $f');
  }
  if (rds0 != null) {
    log
      ..info1('$pad Success!')
      ..debug('summary: ${rds0.summary}');
  }
  return reader;
}

Reader decodeUint8List(Uint8List list, Reader reader,
    {bool throwOnError = true, bool fast = true, int width = 5}) {
  final bytes = new Bytes.fromList(list);
  return decodeBytes(bytes, reader,
      throwOnError: throwOnError, fast: fast, width: width);
}

const int kMinLength = 256;

Reader decodeBytes(Bytes input, Reader reader,
    {bool throwOnError = true,
      bool doLogging = true,
    bool fast = true,
    int width = 5}) {
  final pad = ''.padRight(width);
  RootDataset rds0;

  if (input.length < kMinLength)
    throw ShortFileError('length: ${input.length}');
  try {
    final reader0 = new ByteReader.fromBytes(input, doLogging: doLogging);

    rds0 = reader0.readRootDataset();
    if (rds0 == null) return reader;

    if (reader0.pInfo != null)
      log.debug('$pad    ${reader0.pInfo.summary(rds0)}');

// TODO: move into dataset.warnings.
    final e = rds0[kPixelData];
    if (e == null) {
      log.info1('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

  } on ShortFileError {
    log.warn('$pad ** Short File(${input.length} bytes)');
    if (throwOnError) rethrow;
  } on InvalidTransferSyntax catch (e) {
    log.error(e);
    return reader;
  } catch (e) {
    log.error('Caught $e\n  on input $input');
  }
  if (rds0 != null) {
    log
      ..info1('$pad Success!')
      ..debug('summary: ${rds0.summary}');
  }
  return reader;
}
