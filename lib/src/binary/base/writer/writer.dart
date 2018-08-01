//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:converter/src/binary/base/writer/subwriter.dart';
import 'package:converter/src/element_offsets.dart';

/// A [class] for writing a [ByteRootDataset] to a [Uint8List],
/// Supports encoding all LITTLE ENDIAN [TransferSyntax]es.
abstract class Writer {
  final bool doLogging;
  int fmiEnd;

  /// Creates a new [Writer] where index = 0.
  Writer({this.doLogging = false});

  ElementOffsets get offsets => evrSubWriter.offsets;

  EvrSubWriter get evrSubWriter;
  IvrSubWriter get ivrSubWriter;
  Bytes write() => writeRootDataset();
  int writeFmi() => evrSubWriter.writeFmi();

  RootDataset get rds => evrSubWriter.rds;

  /// Writes a [RootDataset] to a [Uint8List], then returns it.
  Bytes writeRootDataset() {
    int fmiEnd;
    if (!evrSubWriter.isFmiWritten) fmiEnd = evrSubWriter.writeFmi();

    Bytes bytes;
    final ts = evrSubWriter.rds.transferSyntax;
    if (ts.isEvr) {
      bytes = evrSubWriter.writeRootDataset(fmiEnd, ts);
      if (doLogging)
        log
          ..debug('${bytes.length} bytes written')
          ..debug('${evrSubWriter.count} Evr Elements written');
    } else {
      bytes = ivrSubWriter.writeRootDataset(fmiEnd, ts);
      if (doLogging)
        log
          ..debug('${bytes.length} bytes writen')
          ..debug('${evrSubWriter.count} Evr Elements written')
          ..debug('${ivrSubWriter.count} Ivr Elements written');
    }
    return bytes;
  }
}
