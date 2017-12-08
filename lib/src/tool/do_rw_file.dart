// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/src/binary/byte/reader/byte_reader.dart';
import 'package:dcm_convert/src/binary/byte/old/write_bytes.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/tool/job_utils.dart';
import 'package:element/byte_element.dart';
import 'package:path/path.dart' as  path;
import 'package:system/core.dart';

/// Read a file then write it to a buffer.
Future<bool> doRWFile(File f, {bool throwOnError = false, bool fast = true}) async {
  log.level = Level.error;

  final ext = path.extension(f.path).toLowerCase();
  if (ext != '' && ext != '.dcm') {
  	log.error('Unknown File Extension: "$ext"');
  	return false;
  }
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);

  try {
    final Uint8List bytes = await f.readAsBytes();
    final bd = bytes.buffer.asByteData();
    final reader0 = new ByteReader(bd);
    final rds0 = reader0.readRootDataset();
    //TODO: improve next two errors
    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    if (rds0.parseInfo == null) throw 'Bad File - No ParseInfo: $f';
    //TODO: update reader and write to have method called bytes.
    final bytes0 = reader0.bd.buffer.asUint8List();
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS: ${rds0.transferSyntax}''');
    if (rds0.parseInfo != null) log.debug('$pad    ${rds0.parseInfo.summary(rds0)}');

    // TODO: move into dataset.warnings.
    final e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

    // Write the Root Dataset
    ByteDatasetWriter writer;
    if (fast) {
      // Just write bytes don't write the file
      writer = new ByteDatasetWriter(rds0);
    } else {
      final outPath = getTempFile(f.path, 'dcmout');
      writer = new ByteDatasetWriter.toPath(rds0, outPath);
    }
    final bytes1 = writer.write();
    log.debug('$pad    Encoded ${bytes1.length} bytes');

    // Urgent Jim if file has dups then no test is done. Fix it.
    var same = true;
    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      same = bytesEqual(bytes0, bytes1);
      if (same != true) log.warn('$pad Files bytes are different!');
    }
    return same;
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
    rethrow;
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
    rethrow;
  }
}
