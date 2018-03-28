// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/new_writer/writer.dart';
import 'package:convert/src/binary/base/new_writer/subwriter.dart';
import 'package:convert/src/binary/byte/new_writer/byte_subwriter.dart';
import 'package:convert/src/binary/byte/new_writer/logging_byte_subwriter.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A [class] for writing a [BDRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter extends Writer {
  @override
  final EvrSubWriter evrSubWriter;

  /// Creates a new [ByteWriter] where index = 0.
  ByteWriter(BDRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false})
      : evrSubWriter = new ByteEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging);

  /// Writes the [BDRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(BDRootDataset rds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    return new ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }

  /// Creates a new empty [File] from [path], writes the [BDRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(BDRootDataset rds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return new ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }

  @override
  IvrSubWriter get ivrSubWriter => _ivrSubWriter ??= (doLogging)
      ? new LoggingByteIvrSubWriter.from(evrSubWriter)
      : new ByteIvrSubWriter.from(evrSubWriter);

  IvrSubWriter _ivrSubWriter;

  /// Writes the [BDRootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(BDRootDataset rds,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkRootDataset(rds);
    final writer = new ByteWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    return writer.writeRootDataset();
  }

  /// Writes the [BDRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Bytes writeFile(BDRootDataset rds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    final bytes = writeBytes(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [BDRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Bytes writePath(BDRootDataset ds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }
}
