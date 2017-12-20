// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/src/binary/byte/reader/byte_reader.dart';
import 'package:dcm_convert/src/binary/byte/writer/byte_writer.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/tool/job_utils.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';

bool doRWRByteFileSync(File f, {bool fast = true, bool noisy = false}) {
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);
  log.info0('RRWByte $f');

  try {
    final Uint8List bytes = f.readAsBytesSync();
    final bd = bytes.buffer.asByteData();
    final reader0 = new ByteReader(bd, path: f.path);
    final rds0 = reader0.readRootDataset();
    //TODO: improve next two errors
    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    if (rds0.pInfo == null) throw 'Bad File - No ParseInfo: $f';
    final bytes0 = reader0.bd.buffer.asUint8List();
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

    if (noisy) {
      final offsets = reader0.offsets;
      for (var i = 0; i < offsets.length; i++) {
        print('$i: ${offsets.starts[i]} - ${offsets.ends[i]} ${offsets.elements[i]}');
      }
    }

    // Write the Root Dataset
    ByteWriter writer;
    final outPath = getTempFile(f.path, 'dcmout');
    if (fast) {
      // Just write bytes don't write the file
      writer = new ByteWriter(rds0, inputOffsets: reader0.offsets);
    } else {
      writer = new ByteWriter.toPath(rds0, outPath);
    }
    final bytes1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bytes1.length} bytes');

    if (noisy) {
      final wOffsets = writer.outputOffsets;
      for (var i = 0; i < wOffsets.length; i++) {
        print('$i: ${wOffsets.starts[i]} - ${wOffsets.ends[i]} ${wOffsets.elements[i]}');
      }
    }

    if (!fast) {
      log.debug('Re-reading: ${bytes1.length} bytes');
    } else {
      log.debug('Re-reading: ${bytes1.length} bytes from $outPath');
    }
    ByteReader reader1;
    if (fast) {
      // Just read bytes not file
      reader1 = new ByteReader(
          bytes1.buffer.asByteData(bytes1.offsetInBytes, bytes1.lengthInBytes));
    } else {
      reader1 = new ByteReader.fromPath(outPath);
    }
    final rds1 = reader1.readRootDataset();
    log
      ..debug('$pad Read ${reader1.bd.lengthInBytes} bytes')
      ..debug1('$pad DS1: $rds1');

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');
    if (rds0.pInfo != rds1.pInfo) {
      log
        ..warn('$pad ** ParseInfo is Different!')
        ..debug1('$pad rds0: ${rds0.pInfo.summary(rds0)}')
        ..debug1('$pad rds1: ${rds1.pInfo.summary(rds1)}')
        ..debug2(rds0.format(new Formatter(maxDepth: -1)))
        ..debug2(rds1.format(new Formatter(maxDepth: -1)));
    }

    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!fast || !rds0.hasDuplicates) {
      // Compare [ElementOffsets]s
      if (reader0.offsets == writer.outputOffsets) {
        log.debug('$pad ElementOffsets are identical.');
      } else {
        log.warn('$pad ElementOffsets are different!');
      }
    }

    // Compare [Dataset]s - only compares the elements in dataset.map.
    final same = (rds0 == rds1);
    if (same) {
      log.debug('$pad Datasets are identical.');
    } else {
      log.warn('$pad Datasets are different!');
    }

    if (noisy) {
      final aList = rds0.elements.elements;
      final bList = rds1.elements.elements;
      //final length = (aList.length > bList.length) ? aList.length : bList.length;
      if (aList.length != bList.length)
        log.warn('** rds0.length(${bList.length}) != rds1.length(${aList.length})');
      final length = aList.length;
      for (var i = 0; i < length; i++) {
        final x = aList.elementAt(i);
        final y = bList.elementAt(i);
        if (x.eStart != y.eStart ||
            x.code != y.code ||
            x.vrCode != y.vrCode ||
            x.vfLengthField != y.vfLengthField ||
            x.eEnd != y.eEnd) {
          log
	          ..warn('Elements are different:')
	          ..warn('  $i x: $x')
	          ..warn('  $i y: $y');
        }
      }
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
