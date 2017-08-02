// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';
import 'package:dcm_convert/dcm.dart';

final Logger log =
    new Logger("convert/bin/byte/write_file_list.dart", Level.info);

Uint8List writeFile(RootByteDataset rds, String path,
    {bool fmiOnly = false, TransferSyntax outputTS}) {
  var timer = new Timer();
  var total = rds.total;
  log.debug('writing ${rds.runtimeType} to "$path"\n'
      '    with $total Elements\n'
      '    at: ${timer.lastStart} ...');
  if (fmiOnly) log.debug('    fmiOnly: $fmiOnly');

  //  timer.start();
  var bytes = ByteWriter.writePath(rds, path, fmiOnly: fmiOnly);
  timer.stop();

  log.debug('  Elapsed time: ${timer.elapsed}');
  int msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  log.debug('  $msPerElement ms per Element: ');
  return bytes;
}
