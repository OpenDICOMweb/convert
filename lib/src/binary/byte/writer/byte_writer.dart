//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:converter/src/binary/base/writer/writer.dart';
import 'package:converter/src/binary/base/writer/subwriter.dart';
import 'package:converter/src/binary/byte/writer/byte_subwriter.dart';
import 'package:converter/src/encoding_parameters.dart';

/// A [class] for writing a [ByteRootDataset] to a [Uint8List].
/// Supports encoding all little and big endian [TransferSyntax]es.
class ByteWriter extends Writer {
  @override
  final EvrSubWriter evrSubWriter;

  /// Creates a [ByteWriter] where index = 0.
  ByteWriter(ByteRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false})
      : evrSubWriter = ByteEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging);

  @override
  IvrSubWriter get ivrSubWriter =>
      _ivrSubWriter ??= ByteIvrSubWriter.from(evrSubWriter);
  IvrSubWriter _ivrSubWriter;

  /// Writes the [ByteRootDataset] to a [Uint8List],
  /// and returns the [Uint8List].
  static Bytes writeBytes(ByteRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkRootDataset(rds);
    final writer = ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    if (doLogging) log.reset;
    return writer.writeRootDataset().bytes;
  }

  /// Writes the [ByteRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Bytes writeFile(ByteRootDataset rds, File file,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    final bytes = writeBytes(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a empty [File] from [path], writes the [ByteRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Bytes writePath(ByteRootDataset ds, String path,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return writeFile(ds, File(path),
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }
}
