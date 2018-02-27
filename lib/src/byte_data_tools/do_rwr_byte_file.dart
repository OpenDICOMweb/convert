// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';

import 'package:core/core.dart';

import 'package:convert/src/dicom/byte_data/reader/bd_reader.dart';
import 'package:convert/src/dicom/byte_data/writer/bd_writer.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/byte_data_tools/job_utils.dart';

// ignore_for_file: only_throw_errors, avoid_catches_without_on_clauses

Future<bool> doRWRByteFile(File f, {bool fast = true}) async {
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);

  try {
    final reader0 = new BDReader.fromFile(f);
    final rds0 = reader0.readRootDataset();
    //TODO: improve next two errors
    if (rds0 == null) {
      log.info0('Bad File: ${f.path}');
      return false;
    }
    if (rds0.pInfo == null) throw 'Bad File - No ParseInfo: $f';
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

    final offsets = reader0.offsets;
    for (var i = 0; i < offsets.length; i++) {
      print(
          '$i: ${offsets.starts[i]} - ${offsets.ends[i]} ${offsets.elements[i]}');
    }

    // Write the Root Dataset
    BDWriter writer;
    final outPath = getTempFile(f.path, 'dcmout');
    if (fast) {
      // Just write bytes don't write the file
      writer = new BDWriter(rds0, inputOffsets: reader0.offsets);
    } else {
      writer = new BDWriter.toPath(rds0, outPath);
    }
    final bd1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bd1.lengthInBytes} bytes');

    final wOffsets = writer.outputOffsets;
    for (var i = 0; i < wOffsets.length; i++) {
      print(
          '$i: ${wOffsets.starts[i]} - ${wOffsets.ends[i]} ${wOffsets.elements[i]}');
    }

    if (!fast) {
      log.debug('Re-reading: ${bd1.lengthInBytes} bytes');
    } else {
      log.debug('Re-reading: ${bd1.lengthInBytes} bytes from $outPath');
    }
    BDReader reader1;
    if (fast) {
      // Just read bytes not file
      reader1 = new BDReader.fromBytes(bd1);
    } else {
      reader1 = new BDReader.fromPath(outPath);
    }
    final rds1 = reader1.readRootDataset();
    //   BDRootDatasets rds1 = BDWriter.readPath(outPath);
    log
      ..debug('$pad Read ${reader1.rb.lengthInBytes} bytes')
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

    final aList = rds0.elements.values;
    final bList = rds1.elements.values;
    final length = (aList.length > bList.length) ? aList.length : bList.length;
    for (var i = 0; i < length; i++) {
      final x = aList.elementAt(i);
      final y = bList.elementAt(i);
      print('$i x: $x');
      print('$i y: $y');
      if (x.eStart != y.eStart) print('** Starts are different');
      if (x.code != y.code) print('** Codes are different');
      if (x.vrCode != y.vrCode) print('** VRCodes are different');
      if (x.vfLengthField != y.vfLengthField) print('** VFL are different');
      if (x.eEnd != y.eEnd) print('** Ends are different');
    }

    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      final same = uint8ListEqual(bytes0, bd1.buffer.asUint8List());
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
