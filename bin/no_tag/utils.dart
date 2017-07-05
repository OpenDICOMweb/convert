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
import 'package:dcm_convert/src/dicom_no_tag/dcm_byte_reader.dart';
import 'package:dcm_convert/src/dicom_no_tag/dcm_byte_writer.dart';
import 'package:dictionary/dictionary.dart';

final Logger _log =
    new Logger("io/bin/read_files.dart", watermark: Severity.warn);

final Formatter format = new Formatter();

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
  rds = DcmByteReader.readBytes(bytes, path: path, fmiOnly: fmiOnly);

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
    DcmByteReader.readBytes(bytes, path: path, fmiOnly: true);

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
  var bytes = DcmByteWriter.write(rds,
      path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  timer.stop();
  _log.debug('  Elapsed time: ${timer.elapsed}');
  int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  _log.debug('  $msPerElement ms per Element: ');
  return bytes;
}


Uint8List writeFMI(RootByteDataset rds, [String path]) =>
    DcmByteWriter.writePath(rds, path, fmiOnly: true);

Uint8List writeRoot(RootByteDataset rds, {String path}) =>
    DcmByteWriter.writePath(rds, path);

