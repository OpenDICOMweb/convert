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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/binary/base/writer/writer.dart';
import 'package:convert/src/binary/base/writer/subwriter.dart';
import 'package:convert/src/binary/tag/writer/tag_subwriter.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A [class] for writing a [TagRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class TagWriter extends Writer {
  @override
  final EvrSubWriter evrSubWriter;

  /// Creates a new [TagWriter] where index = 0.
  TagWriter(TagRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool doLogging = false})
      : evrSubWriter = new TagEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging),
        super(doLogging: doLogging);

  /// Writes the [TagRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory TagWriter.toFile(TagRootDataset ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    return new TagWriter(ds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }

  /// Creates a new empty [File] from [path], writes the [TagRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory TagWriter.toPath(TagRootDataset rds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return new TagWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }

  @override
  IvrSubWriter get ivrSubWriter =>
      _ivrSubWriter ??= new TagIvrSubWriter.from(evrSubWriter);
  IvrSubWriter _ivrSubWriter;

  /// Writes the [RootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(TagRootDataset rds,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool doLogging = true}) {
    final writer = new TagWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    return writer.writeRootDataset();
  }

  /// Writes the [RootDataset] to a [Uint8List], then writes the
  /// [Uint8List] to the [File], and returns the [Uint8List].
  static Future<Bytes> writeFile(TagRootDataset ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool doAsync = true,
      bool doLogging = false}) async {
    checkFile(file);
    final bytes = writeBytes(ds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    (doAsync)
        ? await file.writeAsBytes(bytes.asUint8List())
        : file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [TagRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Future<Bytes> writePath(TagRootDataset ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool doAsync = true,
      bool doLogging = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        eParams: eParams,
        outputTS: outputTS,
        doAsync: doAsync,
        doLogging: doLogging);
  }
}
