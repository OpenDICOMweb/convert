//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';

import 'package:convert/src/binary/byte/reader/byte_reader.dart';
import 'package:convert/src/binary/byte/writer/byte_writer.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/utilities/io_utils.dart';

// ignore_for_file: only_throw_errors, avoid_catches_without_on_clauses

/// Read a file then write it to a buffer.
Future<bool>  doRWFile(File f,
    {bool throwOnError = true, bool fast = true}) async {

  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);

  var same = true;
  try {
    final bList0 = f.readAsBytesSync();
    final reader0 = new ByteReader(bList0, doLogging: true);
    final rds0 = reader0.readRootDataset();

    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    //  if (reader0.pInfo == null) throw 'Bad File - No ParseInfo: $f';
    //TODO: update reader and write to have method called bytes.
    final bytes0 = reader0.bytesRead;
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS: ${rds0.transferSyntax}''');
    if (reader0.pInfo != null)
      log.debug('$pad    ${reader0.pInfo.summary(rds0)}');

    // TODO: move into dataset.warnings.
    final e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

    // Write the Root Dataset
    ByteWriter writer;
    if (fast) {
      // Just write bytes don't write the file
      writer = new ByteWriter(rds0);
    } else {
      final outPath = getTempFile(f.path, 'dcmout');
      writer = new ByteWriter.toPath(rds0, outPath);
    }
    final bytes1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bytes1.lengthInBytes} bytes');

    // Urgent Jim if file has dups then no test is done. Fix it.
    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      same = bytes0 == bytes1;
      if (same != true) log.warn('$pad Files bytes are different!');
    }
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
    rethrow;
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
    rethrow;
  }
  return same;
}
