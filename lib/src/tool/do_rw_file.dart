// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/dcm.dart';
import 'package:system/system.dart';

/// Read a file then write it to a buffer.
bool doRWFile(File f, [bool throwOnError = false, bool fast = true]) {
  log.level = Level.error;
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  var pad = "".padRight(5);

  try {
    var reader0 = new ByteReader.fromFile(f, fast: true);
    RootByteDataset rds0 = reader0.readRootDataset();
    //TODO: improve next two errors
    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    if (rds0.parseInfo == null) throw 'Bad File - No ParseInfo: $f';
    var bytes0 = reader0.buffer;
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS: ${rds0.transferSyntax}''');
    if (rds0.parseInfo != null) log.debug('$pad    ${rds0.parseInfo.info}');

    // TODO: move into dataset.warnings.
    ByteElement e = rds0[kPixelData];
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
      writer = new ByteWriter.toPath(rds0, outPath, fast: true);
    }
    Uint8List bytes1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bytes1.length} bytes');

   // Urgent Jim if file has dups then no test is done. Fix it.
    bool same = true;
    // If duplicates are present the [ElementList]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      same = bytesEqual(bytes0, bytes1);
      if (same != true) log.warn('$pad Files bytes are different!');
    }
    return same;
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
    return false;
  }
  return false;
}