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
import 'package:io/io.dart';

import 'package:convert/src/binary/base/writer/writer.dart';
import 'package:convert/src/binary/base/writer/subwriter.dart';
import 'package:convert/src/binary/byte/writer/byte_subwriter.dart';
import 'package:convert/src/encoding_parameters.dart';

/// A [class] for writing a [ByteRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter extends Writer {
  @override
  final EvrSubWriter evrSubWriter;

  /// Creates a new [ByteWriter] where index = 0.
  ByteWriter(ByteRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false})
      : evrSubWriter = new ByteEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging);

  /// Writes the [ByteRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(ByteRootDataset rds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    return new ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }

  /// Creates a new empty [File] from [path], writes the [ByteRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(ByteRootDataset rds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return new ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }

  @override
  IvrSubWriter get ivrSubWriter => _ivrSubWriter ??=
       new ByteIvrSubWriter.from(evrSubWriter);

  IvrSubWriter _ivrSubWriter;

  /// Writes the [ByteRootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(ByteRootDataset rds,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkRootDataset(rds);
    final writer = new ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    return writer.writeRootDataset();
  }

  /// Writes the [ByteRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Bytes writeFile(ByteRootDataset rds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    final bytes = writeBytes(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [ByteRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Bytes writePath(ByteRootDataset ds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }
}
