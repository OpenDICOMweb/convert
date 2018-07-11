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

import 'package:convert/src/binary/base/writer/subwriter.dart';
import 'package:convert/src/element_offsets.dart';

/// A [class] for writing a [ByteRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
abstract class Writer {
  final bool doLogging;
  int fmiEnd;

  /// Creates a new [Writer] where index = 0.
  Writer({this.doLogging = false});

  ElementOffsets get offsets => evrSubWriter.offsets;

/*
  /// Writes the [ByteRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory Writer.toFile(File file,

      bool doLogging = false,
      bool showStats = false}) {
    checkFile(file, overwrite: overwrite);
    return new Writer(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseByte: reUseByte,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new empty [File] from [path], writes the [ByteRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory Writer.toPath(ByteRootDataset ds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseByte = false,
      bool doLogging = false,
      bool showStats = false}) {
    checkPath(path);
    return new Writer(ds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseByte: reUseByte,
        doLogging: doLogging,
        showStats: showStats);
  }
*/

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
/*
  /// Writes the [ByteRootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes({bool doLogging = true}) {
    checkRootDataset(rds);
    final writer = new Writer(doLogging: doLogging);
    return writer.writeRootDataset();
  }

  /// Writes the [ByteRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Bytes writeFile(ByteRootDataset ds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseByte = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseByte: reUseByte,
        doLogging: doLogging,
        showStats: showStats);
    file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [ByteRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Bytes writePath(ByteRootDataset ds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseByte = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseByte: reUseByte,
        doLogging: doLogging,
        showStats: showStats);
  }
  */
}