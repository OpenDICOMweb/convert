// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/format.dart';
import 'package:common/logger.dart';
import 'package:common/timestamp.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dictionary/dictionary.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Logger _log =
    new Logger("io/bin/read_files.dart", watermark: Severity.info);

final Formatter format = new Formatter();

String getPaddedInt(int n, int width) =>
    (n == null) ? "" : '${"$n".padLeft(width)}';

String cleanPath(String path) => path.replaceAll('\\', '/');

bool byteReadWriteFileChecked(String fPath,
    [int fileNumber, int width = 5, bool throwOnError = true]) {

  log.reset;
  var n = getPaddedInt(fileNumber, width);
  fPath = cleanPath(fPath);
  log.config('$n: Reading: $fPath');

  File f = new File(fPath);
  try {
    var reader0 = new ByteReader.fromFile(f);
    var rds0 = reader0.readRootDataset();
    var bytes0 = reader0.bytes;
    log.debug('  Read ${bytes0.lengthInBytes} bytes');
    log.info('  DS0: $rds0');

    BytePixelData bpd = rds0[kPixelData];
    log.debug2('bpd: $bpd');
    log.info(' VFFragments: ${bpd.fragments}');

    // Write a File
    var writer = new ByteWriter.toPath(rds0, outPath);
    var bytes1 = writer.writeRootDataset();
    log.debug('  Wrote ${bytes1.length} bytes');

    log.info('Re-reading: $outPath');
    var reader1 = new ByteReader.fromPath(fPath);
    var rds1 = reader1.readRootDataset();
    //   RootByteDataset rds1 = ByteReader.readPath(outPath);
    log.debug('  Read ${reader1.bd.lengthInBytes} bytes');
    log.info('  DS1: $rds1');

    if (rds0.parseInfo != rds1.parseInfo) {
      log.warn('  *** ParseInfo is Different!');
      log.debug('  ${rds0.parseInfo}');
      log.debug('  ${rds1.parseInfo}');
      log.debug2(rds0.format(new Formatter(maxDepth: -1)));
      log.debug2(rds1.format(new Formatter(maxDepth: -1)));
    }

    // Compare [Dataset]s
    if (reader0.elementList == writer.elementList) {
      log.info('ElementLists are identical.');
    } else {
      log.info('ElementLists are different!');
    }

    // Compare [Dataset]s
    if (rds0 == rds1) {
      log.info('Datasets are identical.');
    } else {
      log.info('Datasets are different!');
    }

    //   FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
    var same = bytesEqual(bytes0, bytes1, true);
    if (same == true) {
      log.info('Files are identical.');
    } else {
      log.info('Files are different!');
    }
    return same;
  } on ShortFileError {
    log.warn('Short File(${f.lengthSync()} bytes): $f');
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
  }
  return false;
}

RootByteDataset readFileTimed(File file,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    Severity logLevel: Severity.warn,
    bool printDS: false}) {
  _log.watermark = logLevel;
  var path = file.path;
  var timer = new Stopwatch();
  var timestamp = new Timestamp();

  _log.debug('Reading $path ...\n'
      '   fmiOnly: $fmiOnly\n'
      '   at: $timestamp');

  timer.start();
//  var file = new File(path);
  Uint8List bytes = file.readAsBytesSync();
  timer.stop();
  _log.debug('   read ${bytes.length} bytes in ${timer.elapsedMicroseconds}us');

  if (bytes.length < 1024)
    _log.warn('***** Short file length(${bytes.length}): $path');

  Dataset rds;
  timer.start();
  rds = ByteReader.readBytes(bytes, path: path, fmiOnly: fmiOnly);

  timer.stop();
  if (rds == null) {
    _log.error('Null Instance $path');
    return null;
  } else {
    var n = rds.total;
    var us = timer.elapsedMicroseconds;
    var msPerElement = us ~/ n;
    _log.debug('  Elapsed time: ${timer.elapsed}');
    _log.debug('  $n elements');
    _log.debug('  ${msPerElement}us per element');

    _log.debug('  Has valid TS(${rds.hasSupportedTransferSyntax}) '
        '${rds.transferSyntax}');
    // _log.debug('RDS: ${rds.info}');
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
  _log.debug('current dir: ${Directory.current}');
  _log.debug('Writing ${rds.runtimeType} to "$path"\n'
      '    with $total Elements\n'
      '    fmiOnly: $fmiOnly\n'
      '    at: $timestamp ...');

  timer.start();
  var bytes =
      ByteWriter.writeBytes(rds, path: path, fmiOnly: fmiOnly, fast: fast);
  timer.stop();
  _log.debug('  Elapsed time: ${timer.elapsed}');
  int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  _log.debug('  $msPerElement ms per Element: ');
  return bytes;
}

Uint8List writeFMI(RootByteDataset rds, [String path]) =>
    ByteWriter.writePath(rds, path, fmiOnly: true);

Uint8List writeRoot(RootByteDataset rds, {String path}) =>
    ByteWriter.writePath(rds, path);
