//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:converter/src/binary/byte/reader/byte_reader.dart';
import 'package:converter/src/binary/byte/writer/byte_writer.dart';
import 'package:converter/src/errors.dart';

// ignore_for_file: avoid_catches_without_on_clauses

//TODO:  Move to IO
String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Formatter format = new Formatter();

bool byteReadWriteFileChecked(String path,
    {int fileNumber, int width = 5, bool fast = true, bool doLogging = false}) {
  var success = true;
  final n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(2);
  final fPath = cleanPath(path);
  log.info('$n: Reading: $fPath');

  final f = new File(fPath);
  try {
    final bList0 = f.readAsBytesSync();
    if (doLogging) log.info('  File Length: ${bList0.length}');
    final reader0 = new ByteReader(bList0, doLogging: doLogging);
    final rds0 = reader0.readRootDataset();
    final bytes0 = reader0.rb.buffer;
    log.info('$n:   read ${bytes0.length} bytes');
    final e = rds0[kPixelData];
    if (e == null) log.warn('$pad ** Pixel Data Element not present');

    log.debug('${rds0.summary}');
    //..debug('${reader0.pInfo}');

    // Write the Root Dataset
    ByteWriter writer;
    if (fast) {
      // Just write bytes not file
      log.debug('  Writing ${rds0.length} bytes');
      writer = new ByteWriter(rds0, doLogging: doLogging);
    } else {
      log.debug('  Writing (${rds0.length} bytes) to: $outPath');
      writer = new ByteWriter(rds0, doLogging: doLogging);
    }
    final bytes1 = writer.writeRootDataset();

    log.debug('  Bytes written: offset(${bytes1.offset}) '
        'length(${bytes1.length})\n');

    ByteReader reader1;
    if (fast) {
      // Just read bytes not file
      log.debug('  Reading (${bytes1.length} bytes');
      reader1 = new ByteReader.fromBytes(bytes1, doLogging: doLogging);
    } else {
      final f = new File(outPath);
      log.debug('  Reading (${f.lengthSync()} bytes) from: $outPath');
      reader1 = new ByteReader.fromFile(f, doLogging: doLogging);
    }
    final rds1 = reader1.readRootDataset();

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');

    if (reader0.pInfo != reader1.pInfo) {
      log
        ..warn('$pad ** ParseInfo is Different!')
        ..debug1('$pad rds0: ${reader0.pInfo.summary(rds0)}')
        ..debug1('$pad rds1: ${reader1.pInfo.summary(rds1)}')
        ..debug2(rds0.format(new Formatter(maxDepth: -1)))
        ..debug2(rds1.format(new Formatter(maxDepth: -1)));
    }

    // If duplicates are present the [ElementOffsets]s will not be equal.
    if (!rds0.hasDuplicates) {
      // Compare [ElementOffsets]s
      if (reader0.offsets != writer.offsets)
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

ByteRootDataset readFileTimed(File file,
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

  if (bytes.length < 1024)
    log.warn('***** Short file length(${bytes.length}): $path');

  RootDataset rds;
  timer.start();
  rds = ByteReader.readBytes(bytes);

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

ByteRootDataset readFMI(Uint8List bytes, [String path = '']) =>
    ByteReader.readTypedData(bytes);

Bytes writeTimed(ByteRootDataset rds,
    {String path = '',
    bool fast = true,
    bool fmiOnly = false,
    TransferSyntax targetTS}) {
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
  final bytes = ByteWriter.writeBytes(rds);
  timer.stop();
  log.debug('  Elapsed time: ${timer.elapsed}');
  final msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  log.debug('  $msPerElement ms per Element: ');
  return bytes;
}

Bytes writeFMI(ByteRootDataset rds, [String path]) =>
    ByteWriter.writeBytes(rds);

Bytes writeRoot(ByteRootDataset rds, {String path}) =>
    ByteWriter.writeBytes(rds);
