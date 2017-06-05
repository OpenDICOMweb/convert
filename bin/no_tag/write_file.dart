// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/format.dart';
import 'package:common/logger.dart';
import 'package:convertX/timer.dart';
import 'package:core/core.dart';
import 'package:convertX/src/dicom_no_tag/dcm_byte_writer.dart';
import 'package:dictionary/dictionary.dart';

final Logger log = new Logger("convert/bin/no_tag/write_file_list.dart",
    watermark: Severity.info);

final Formatter format = new Formatter();

Uint8List writeFile(RootByteDataset rds, String path,
    {bool fmiOnly = false, TransferSyntax targetTS}) {
    var file = new File(path);
    var timer = new Timer();
    var total = rds.total;
    log.info('writing ${rds.runtimeType} to "$path"\n'
        '    with $total Elements\n'
        '    at: ${timer.startTime} ...');
    if (fmiOnly) log.debug('    fmiOnly: $fmiOnly');

    timer.start();
    DcmByteWriter.writeFile(rds, file, fmiOnly: fmiOnly);
    timer.stop();

    log.info('  Elapsed time: ${timer.elapsed}');
    int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
    log.info('  $msPerElement ms per Element: ');
    return writer.bytes;
}

Uint8List writeFMI(RootByteDataset rds, [String path]) =>
    DcmByteWriter.write(rds, path: path, fmiOnly: true);

Uint8List writeRoot(RootByteDataset rds, {String path}) =>
    DcmByteWriter.write(rds, path: path);


