// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/dataset.dart';
import 'package:dcm_convert/byte_convert.dart';
import 'package:system/core.dart';
import 'package:timer/timestamp.dart';
import 'package:uid/uid.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Formatter format = new Formatter();

bool byteReadWriteFileChecked(String path,
    {int fileNumber, int width = 5, bool fast = true}) {
  var success = true;
  final n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(width);
  final fPath = cleanPath(path);
  log.info1('$n: Reading: $fPath');

  final f = new File(fPath);
  try {
    final reader0 = new ByteDatasetReader.fromFile(f);
    final rds0 = reader0.read();
    final bytes0 = reader0.rootBytes;
    final e = rds0[kPixelData];
    if (e == null) log.warn('$pad ** Pixel Data Element not present');

    log..debug('${rds0.summary}')..debug('${rds0.parseInfo}');

    // Write the Root Dataset
    ByteDatasetWriter writer;
    if (fast) {
      // Just write bytes not file
      writer = new ByteDatasetWriter(rds0);
    } else {
      writer = new ByteDatasetWriter.toPath(rds0, outPath);
    }
    final bytes1 = writer.write();

    ByteDatasetReader reader1;
    if (fast) {
      // Just read bytes not file
      reader1 = new ByteDatasetReader(
          bytes1.buffer.asByteData(bytes1.offsetInBytes, bytes1.lengthInBytes));
    } else {
      reader1 = new ByteDatasetReader.fromPath(outPath);
    }
    final rds1 = reader1.read();

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
    if (!rds0.hasDuplicates) {
      // Compare [ElementOffsets]s
      if (reader0.offsets != writer.outputOffsets)
        log.warn('$pad ElementOffsetss are different!');
    }

    // Compare [Dataset]s - only compares the elements in dataset.map.
    final same = (rds0 == rds1);
    if (!same) {
      success = false;
      log.warn('$pad Datasets are different!');
    }

    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      final same = bytesEqual(bytes0, bytes1);
      if (!same) {
        success = false;
        log.warn('$pad Files bytes are different!');
      }
    }
    if (same) log.info1('$pad Success!');
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
    rethrow;
  } catch (e) {
    log.error(e);
   // if (throwOnError) rethrow;
    rethrow;
  }
  return success;
}

RootDatasetByte readFileTimed(File file,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    Level level = Level.warn,
    bool printDS: false}) {
  log.level = level;
  final path = file.path;
  final timer = new Stopwatch()..start();

  final bytes = file.readAsBytesSync();
  timer.stop();
//  log.debug('   read ${bytes.length} bytes in ${timer.elapsedMicroseconds}us');

  if (bytes.length < 1024) log.warn('***** Short file length(${bytes.length}): $path');

  RootDataset rds;
  timer.start();
  rds = ByteDatasetReader.readBytes(bytes, path: path, fmiOnly: fmiOnly);

  timer.stop();
  if (rds == null) {
    log.error('Null Instance $path');
    return null;
  } else {
    final n = rds.total;
    final us = timer.elapsedMicroseconds;
    final msPerElement = us ~/ n;
    log
      ..debug('  Elapsed time: ${timer.elapsed}')
      ..debug('  $n elements')
      ..debug('  ${msPerElement}us per element')
      ..debug('  Has valid TS(${rds.hasSupportedTransferSyntax}) '
          '${rds.transferSyntax}');
    // log.debug('RDS: ${rds.info}');
    if (printDS) rds.format(new Formatter());
    return rds;
  }
}

RootDatasetByte readFMI(Uint8List bytes, [String path = '']) =>
    ByteDatasetReader.readBytes(bytes, path: path, fmiOnly: true);

Uint8List writeTimed(RootDatasetByte rds,
    {String path = '', bool fast = true, bool fmiOnly = false, TransferSyntax targetTS}) {
  final timer = new Stopwatch();
  final timestamp = new Timestamp();
  final total = rds.total;
  log
    ..debug('current dir: ${Directory.current}')
    ..debug('Writing ${rds.runtimeType} to "$path"\n'
        '    with $total Elements\n'
        '    fmiOnly: $fmiOnly\n'
        '    at: $timestamp ...');

  timer.start();
  final bytes = ByteDatasetWriter.writeBytes(rds, path: path, fmiOnly: fmiOnly, fast: fast);
  timer.stop();
  log.debug('  Elapsed time: ${timer.elapsed}');
  final msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  log.debug('  $msPerElement ms per Element: ');
  return bytes;
}

Future<Uint8List> writeFMI(RootDatasetByte rds, [String path]) async =>
    await ByteDatasetWriter.writePath(rds, path, fmiOnly: true);

Future<Uint8List> writeRoot(RootDatasetByte rds, {String path}) =>
    ByteDatasetWriter.writePath(rds, path);