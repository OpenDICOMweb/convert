// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:logger/logger.dart';
import 'package:system/core.dart';
import 'package:timer/timestamp.dart';


String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Formatter format = new Formatter();

bool byteReadWriteFileChecked(String fPath,
    [int fileNumber,
    int width = 5,
    bool throwOnError = true,
    bool fast = true]) {
  bool success = true;
  var n = getPaddedInt(fileNumber, width);
  var pad = "".padRight(width);
  fPath = cleanPath(fPath);
  log.info1('$n: Reading: $fPath');

  File f = new File(fPath);
  try {
    var reader0 = new ByteReader.fromFile(f);
    RootByteDataset rds0 = reader0.readRootDataset();
    var bytes0 = reader0.bytes;
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS: ${rds0.transferSyntax}
$pad    ${rds0.parseInfo.info}''');

    ByteElement e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
//      BytePixelData bpd = e;
      log.debug1('$pad  bpd: ${e.info}');
    }

    // Write the Root Dataset
    ByteWriter writer;
    if (fast) {
      // Just write bytes not file
      writer = new ByteWriter(rds0);
    } else {
      writer = new ByteWriter.toPath(rds0, outPath);
    }
    Uint8List bytes1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bytes1.length} bytes');

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
    var rds1 = reader1.readRootDataset();
    //   RootByteDataset rds1 = ByteReader.readPath(outPath);
    log.debug('$pad Read ${reader1.bd.lengthInBytes} bytes');
    log.debug1('$pad DS1: $rds1');

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');
    if (rds0.parseInfo != rds1.parseInfo) {
      log.warn('$pad ** ParseInfo is Different!');
      log.debug1('$pad rds0: ${rds0.parseInfo.info}');
      log.debug1('$pad rds1: ${rds1.parseInfo.info}');
      log.debug2(rds0.format(new Formatter(maxDepth: -1)));
      log.debug2(rds1.format(new Formatter(maxDepth: -1)));
    }

    // If duplicates are present the [ElementList]s will not be equal.
    if (!rds0.hasDuplicates) {
      // Compare [ElementList]s
      if (reader0.elementList == writer.elementList) {
        log.debug('$pad ElementLists are identical.');
      } else {
        log.warn('$pad ElementLists are different!');
      }
    }

    // Compare [Dataset]s - only compares the elements in dataset.map.
    var same = (rds0 == rds1);
    if (same) {
      log.debug('$pad Datasets are identical.');
    } else {
      success = false;
      log.warn('$pad Datasets are different!');
    }

    // If duplicates are present the [ElementList]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      var same = bytesEqual(bytes0, bytes1);
      if (same == true) {
        log.debug('$pad Files bytes are identical.');
      } else {
        success = false;
        log.warn('$pad Files bytes are different!');
      }
    }
    if (same) log.info1('$pad Success!');
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
  }
  return success;
}

RootByteDataset readFileTimed(File file,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    Level level = Level.warn,
    bool printDS: false}) {
  log.level = level;
  var path = file.path;
  var timer = new Stopwatch();
  var timestamp = new Timestamp();

  log.debug('Reading $path ...\n'
      '   fmiOnly: $fmiOnly\n'
      '   at: $timestamp');

  timer.start();
//  var file = new File(path);
  Uint8List bytes = file.readAsBytesSync();
  timer.stop();
  log.debug('   read ${bytes.length} bytes in ${timer.elapsedMicroseconds}us');

  if (bytes.length < 1024)
    log.warn('***** Short file length(${bytes.length}): $path');

  Dataset rds;
  timer.start();
  rds = ByteReader.readBytes(bytes, path: path, fmiOnly: fmiOnly);

  timer.stop();
  if (rds == null) {
    log.error('Null Instance $path');
    return null;
  } else {
    var n = rds.total;
    var us = timer.elapsedMicroseconds;
    var msPerElement = us ~/ n;
    log.debug('  Elapsed time: ${timer.elapsed}');
    log.debug('  $n elements');
    log.debug('  ${msPerElement}us per element');

    log.debug('  Has valid TS(${rds.hasSupportedTransferSyntax}) '
        '${rds.transferSyntax}');
    // log.debug('RDS: ${rds.info}');
    if (printDS) rds.format(new Formatter());
    return rds;
  }
}

RootByteDataset readFMI(Uint8List bytes, [String path = ""]) =>
    ByteReader.readBytes(bytes, path: path, fmiOnly: true);

Uint8List writeTimed(RootByteDataset rds,
    {String path = "",
    bool fast = true,
    bool fmiOnly = false,
    TransferSyntax targetTS}) {
  var timer = new Stopwatch();
  var timestamp = new Timestamp();
  var total = rds.total;
  log.debug('current dir: ${Directory.current}');
  log.debug('Writing ${rds.runtimeType} to "$path"\n'
      '    with $total Elements\n'
      '    fmiOnly: $fmiOnly\n'
      '    at: $timestamp ...');

  timer.start();
  var bytes =
      ByteWriter.writeBytes(rds, path: path, fmiOnly: fmiOnly, fast: fast);
  timer.stop();
  log.debug('  Elapsed time: ${timer.elapsed}');
  int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  log.debug('  $msPerElement ms per Element: ');
  return bytes;
}

Future<Uint8List> writeFMI(RootByteDataset rds, [String path]) =>
    ByteWriter.writePath(rds, path, fmiOnly: true);

Future<Uint8List> writeRoot(RootByteDataset rds, {String path}) =>
    ByteWriter.writePath(rds, path);
