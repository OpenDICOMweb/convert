// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:core/core.dart';

Future<Uint8List> writeFile(BDRootDataset rds, String path,
    {bool fmiOnly = false, TransferSyntax outputTS}) {
  final timer = new Timer();
  final total = rds.total;
  log.debug('writing ${rds.runtimeType} to "$path"\n'
      '    with $total Elements\n'
      '    at: ${timer.lastStart} ...');
  if (fmiOnly) log.debug('    fmiOnly: $fmiOnly');

  //  timer.start();
  final bytes = BDWriter.writePath(rds, path);
  timer.stop();

  final msPerElement = (timer.elapsedMicroseconds ~/ total) ~/ 1000;
  log
    ..debug('  Elapsed time: ${timer.elapsed}')
    ..debug('  $msPerElement ms per Element: ');
  return bytes;
}
