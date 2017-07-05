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
import 'package:dcm_convert/src/dicom_no_tag/dcm_writer.dart';
import 'package:dcm_convert/src/dicom_no_tag/old/dataset.dart';
import 'package:dictionary/dictionary.dart';

final Logger log = new Logger("convert/bin/no_tag/write_file_list.dart",
    watermark: Severity.info);

final Formatter format = new Formatter();

Uint8List writeDataset(RootDataset rds, String path,
    {bool fmiOnly = false, TransferSyntax targetTS}) {
    var file = new File(path);
    var timer = new Stopwatch();
    var timestamp = new Timestamp();
    var total = rds.total;
    log.info('writing ${rds.runtimeType} to "$path"\n'
        '    with $total Elements\n'
        '    at: $timestamp ...');
    if (fmiOnly) log.debug('    fmiOnly: $fmiOnly');

    timer.start();
    var writer = new DcmWriter(rds, path: path);
    if (fmiOnly) {
      writer.writeFMI();
    } else {
      writer.writeRootDataset();
    }
    file.writeAsBytesSync(writer.bytes);
    timer.stop();

    log.info('  Elapsed time: ${timer.elapsed}');
    int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
    log.info('  $msPerElement ms per Element: ');
    return writer.bytes;
}

Uint8List writeFMI(RootDataset rds, [String path]) =>
    DcmWriter.fmi(rds, path: path);

Uint8List writeRoot(RootDataset rds, {String path}) =>
    DcmWriter.rootDataset(rds, path: path);


