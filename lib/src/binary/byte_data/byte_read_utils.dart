// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/byte_data/reader/bd_reader.dart';
import 'package:convert/src/binary/byte_data/writer/bd_writer.dart';
import 'package:convert/src/errors.dart';
import 'package:convert/src/utilities/io_utils.dart';

// ignore_for_file: avoid_catches_without_on_clauses

//TODO:  Move to IO
String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Formatter format = new Formatter();

bool byteReadWriteFileChecked(String path,
    {int fileNumber, int width = 5, bool fast = true}) {
  var success = true;
  final n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(width);
  final fPath = cleanPath(path);
  log.info('$n: Reading: $fPath');

  final f = new File(fPath);
  try {
    final reader0 = new BDReader.fromFile(f);
    final rds0 = reader0.readRootDataset();
    final bytes0 = reader0.rb.bytes;
    log.info('$n:   length: ${bytes0.lengthInBytes}');
    final e = rds0[kPixelData];
    if (e == null) log.warn('$pad ** Pixel Data Element not present');

    log..debug('${rds0.summary}')..debug('${rds0.pInfo}');

    // Write the Root Dataset
    BDWriter writer;
    if (fast) {
      // Just write bytes not file
      writer = new BDWriter(rds0, inputOffsets: reader0.offsets);
    } else {
      writer = new BDWriter.toPath(rds0, outPath, inputOffsets: reader0.offsets);
    }
    final bytes1 = writer.writeRootDataset();
    log.debug('Bytes written: offset(${bytes1.offsetInBytes}) '
        'length(${bytes1.lengthInBytes})\n');

    BDReader reader1;
    if (fast) {
      // Just read bytes not file
      reader1 = new BDReader(new ReadBuffer.fromBytes(bytes1));
    } else {
      reader1 = new BDReader.fromPath(outPath);
    }
    final rds1 = reader1.readRootDataset();

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
    if (!rds0.hasDuplicates) {
      // Compare [ElementOffsets]s
      if (reader0.offsets != writer.outputOffsets)
        log.warn('$pad ElementOffsets are different!');
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
      final same = bytes0 == bytes1;
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

BDRootDataset readFileTimed(File file,
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
  rds = BDReader.readBytes(bytes, path: path);

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

BDRootDataset readFMI(Uint8List bytes, [String path = '']) =>
    BDReader.readTypedData(bytes, path: path);

Bytes writeTimed(BDRootDataset rds,
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
  final bytes = BDWriter.writeBytes(rds, path: path);
  timer.stop();
  log.debug('  Elapsed time: ${timer.elapsed}');
  final msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  log.debug('  $msPerElement ms per Element: ');
  return bytes;
}

Future<Bytes> writeFMI(BDRootDataset rds, [String path]) async =>
    await BDWriter.writePath(rds, path);

Future<Bytes> writeRoot(BDRootDataset rds, {String path}) =>
    BDWriter.writePath(rds, path);
