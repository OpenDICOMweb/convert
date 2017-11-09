// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:element/byte_element.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/byte/read_bytes.dart';
import 'package:dcm_convert/src/binary/byte/write_bytes.dart';
import 'package:dcm_convert/src/tool/job_utils.dart';
import 'package:dcm_convert/src/errors.dart';

Future<bool> doRWRByteFile(File f, {bool fast = true}) async {
  log.level = Level.error;
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);

  try {
    final Uint8List bytes = await f.readAsBytes();
    final bd = bytes.buffer.asByteData();
    final reader0 = new ByteDatasetReader(bd, fast: true);
    final rds0 = reader0.read();
    //TODO: improve next two errors
    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    if (rds0.parseInfo == null) throw 'Bad File - No ParseInfo: $f';
    final bytes0 = reader0.rootBytes;
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS: ${rds0.transferSyntax}''');
    if (rds0.parseInfo != null) log.debug('$pad    ${rds0.parseInfo.info}');

    // TODO: move into dataset.warnings.
    final e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

    // Write the Root Dataset
    ByteDatasetWriter writer;
    final outPath = getTempFile(f.path, 'dcmout');
    if (fast) {
      // Just write bytes don't write the file
      writer = new ByteDatasetWriter(rds0);
    } else {
      writer = new ByteDatasetWriter.toPath(rds0, outPath, fast: true);
    }
    final bytes1 = writer.write();
    log.debug('$pad    Encoded ${bytes1.length} bytes');

    if (!fast) {
      log.debug('Re-reading: ${bytes1.length} bytes');
    } else {
      log.debug('Re-reading: ${bytes1.length} bytes from $outPath');
    }
    ByteDatasetReader reader1;
    if (fast) {
      // Just read bytes not file
      reader1 = new ByteDatasetReader(
          bytes1.buffer.asByteData(bytes1.offsetInBytes, bytes1.lengthInBytes));
    } else {
      reader1 = new ByteDatasetReader.fromPath(outPath);
    }
    final rds1 = reader1.read();
    //   RootDatasetBytes rds1 = ByteReader.readPath(outPath);
    log
      ..debug('$pad Read ${reader1.rootBytes.lengthInBytes} bytes')
      ..debug1('$pad DS1: $rds1');

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');
    if (rds0.parseInfo != rds1.parseInfo) {
      log
        ..warn('$pad ** ParseInfo is Different!')
        ..debug1('$pad rds0: ${rds0.parseInfo.info}')
        ..debug1('$pad rds1: ${rds1.parseInfo.info}')
        ..debug2(rds0.format(new Formatter(maxDepth: -1)))
        ..debug2(rds1.format(new Formatter(maxDepth: -1)));
    }

    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!fast || !rds0.hasDuplicates) {
      // Compare [ElementOffsets]s
      if (reader0.offsets == writer.outputOffsets) {
        log.debug('$pad ElementOffsetss are identical.');
      } else {
        log.warn('$pad ElementOffsetss are different!');
      }
    }

    // Compare [Dataset]s - only compares the elements in dataset.map.
    final same = (rds0 == rds1);
    if (same) {
      log.debug('$pad Datasets are identical.');
    } else {
      log.warn('$pad Datasets are different!');
    }

    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      final same = bytesEqual(bytes0, bytes1);
      if (same == true) {
        log.debug('$pad Files bytes are identical.');
      } else {
        log.warn('$pad Files bytes are different!');
      }
    }
    if (same) log.info0('$pad Success!');
    return same;
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
    rethrow;
  } catch (e) {
    log.error(e);
   // if (throwOnError) rethrow;
    rethrow;
   // return false;
  }
}
