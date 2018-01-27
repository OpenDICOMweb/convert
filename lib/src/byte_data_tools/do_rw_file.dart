// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:path/path.dart' as  path;

import 'package:convert/src/dicom/byte_data/reader/bd_reader.dart';
import 'package:convert/src/dicom/byte_data/writer/bd_writer.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/byte_data_tools/job_utils.dart';

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
    final reader0 = new BDReader(bd);
    final rds0 = reader0.readRootDataset();
    //TODO: improve next two errors
    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    if (rds0.pInfo == null) throw 'Bad File - No ParseInfo: $f';
    //TODO: update reader and write to have method called bytes.
    final bytes0 = reader0.rb.asUint8List();
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS: ${rds0.transferSyntax}''');
    if (rds0.pInfo != null) log.debug('$pad    ${rds0.pInfo.summary(rds0)}');

    // TODO: move into dataset.warnings.
    final e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

    // Write the Root Dataset
    BDWriter writer;
    if (fast) {
      // Just write bytes don't write the file
      writer = new BDWriter(rds0);
    } else {
      final outPath = getTempFile(f.path, 'dcmout');
      writer = new BDWriter.toPath(rds0, outPath);
    }
    final bd1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bd.lengthInBytes} bytes');

    // Urgent Jim if file has dups then no test is done. Fix it.
    var same = true;
    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      same = bytesEqual(bytes0, bd1.buffer.asUint8List());
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
