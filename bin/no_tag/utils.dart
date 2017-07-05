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
import 'package:dcm_convert/src/dicom_no_tag/dcm_reader.dart';
import 'package:dcm_convert/src/dicom_no_tag/dcm_writer.dart';
import 'package:dcm_convert/src/dicom_no_tag/old/dataset.dart';
import 'package:dictionary/dictionary.dart';

final Logger _log = new Logger("io/bin/read_file.dart", watermark: Severity.warn);

final Formatter format = new Formatter();

RootDataset readFile(File file,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    Severity logLevel: Severity.warn,
    bool printDS: false}) {
  _log.watermark = logLevel;
  var path = file.path;
  var timer = new Stopwatch();
  var timestamp = new Timestamp();

  _log.info('Reading $path ...\n'
      '   fmiOnly: $fmiOnly\n'
      '   at: $timestamp');

  timer.start();
//  var file = new File(path);
  Uint8List bytes = file.readAsBytesSync();
  timer.stop();
  _log.info('   read ${bytes.length} bytes in ${timer.elapsedMicroseconds}us');

  if (bytes.length < 1024) _log.warn('***** Short file length(${bytes.length}): $path');

  RootDataset rds;
  timer.start();

  rds = DcmReader.readBytes(bytes, fmiOnly: fmiOnly, path: path);

  timer.stop();
  if (rds == null) {
    _log.error('Null Instance $path');
    return null;
  } else {
    var n = rds.total;
    var us = timer.elapsedMicroseconds;
    var msPerElement = us ~/ n;
    _log.info('  Elapsed time: ${timer.elapsed}');
    _log.info('  $n elements');
    _log.info('  ${msPerElement}us per element');

    _log.info('  Has valid TS(${rds.hasValidTransferSyntax}) '
        '${rds.transferSyntax}');
    // _log.info('RDS: ${rds.info}');
    if (printDS) formatDataset(rds);
    return rds;
  }
}

void formatDataset(RootDataset rds, [bool includePrivate = true]) {
  var z = new Formatter(maxDepth: 146);
  _log.debug(rds.format(z));
}

/*
RootDataset readFMI(Uint8List bytes, [String path = ""]) => DcmReader.readFmiOnly(bytes);

RootDataset readRoot(Uint8List bytes, [String path = ""]) {
  ByteData bd = bytes.buffer.asByteData();
  DcmReader reader = new DcmReader(bd);
  RootDataset rds = reader.readRootDataset();
  return rds;
}

RootDataset readRootNoFMI(Uint8List bytes, [String path = ""]) {
  ByteData bd = bytes.buffer.asByteData();
  DcmReader decoder = new DcmReader(bd);
  Dataset rds = decoder.xReadDataset();
  return rds;
}
*/

Uint8List writeDatasetWithTimer(RootDataset rds,
    {String path = "", bool fast = true, bool fmiOnly = false, TransferSyntax targetTS}) {
  var timer = new Stopwatch();
  var timestamp = new Timestamp();
  var total = rds.total;
  _log.debug('current dir: ${Directory.current}');
  _log.info('Writing ${rds.runtimeType} to "$path"\n'
      '    with $total Elements\n'
      '    fmiOnly: $fmiOnly\n'
      '    at: $timestamp ...');

  timer.start();
  var writer = new DcmWriter(rds, path: path);
  if (fmiOnly) {
    writer.writeFMI();
  } else {
    writer.writeRootDataset();
  }
  timer.stop();

  _log.info('  Elapsed time: ${timer.elapsed}');
  int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  _log.info('  $msPerElement ms per Element: ');
  return writer.bytes;
}

//Urgent: make these DcmWriter static
Uint8List writeFMI(RootDataset rds, [String path]) => DcmWriter.fmi(rds, path: path);

Uint8List writeRoot(RootDataset rds, {String path}) => DcmWriter.rootDataset(rds, path: path);

Uint8List writeRootNoFMI(RootDataset rds, {String path = ""}) => DcmWriter.fmi(rds, path: path);
