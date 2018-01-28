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

import 'package:convert/src/bytes/bytes.dart';
import 'package:convert/src/dicom/base/writer/dcm_writer_base.dart';
import 'package:convert/src/dicom/base/writer/evr_writer.dart';
import 'package:convert/src/dicom/base/writer/ivr_writer.dart';
import 'package:convert/src/dicom/tag/writer/evr_tag_writer.dart';
import 'package:convert/src/dicom/tag/writer/ivr_tag_writer.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A [class] for writing a [TagRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class TagWriter {
  final RootDataset rds;
  final String path;
  final bool overwrite;
  final EncodingParameters eParams;
  final TransferSyntax outputTS;
  final int minLength;
  final ElementOffsets inputOffsets;
  final bool reUseBD;
  final bool doLogging;
  final bool showStats;
  final EvrWriter _evrWriter;
  IvrWriter _ivrWriter;
  ElementOffsets outputOffsets;

  /// Creates a new [TagWriter] where index = 0.
  TagWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minLength = kDefaultWriteBufferLength,
      this.inputOffsets,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats = false})
      : _evrWriter = (doLogging)
            ? new EvrLoggingTagWriter(rds, eParams, minLength, inputOffsets, reUseBD:
  reUseBD)
            : new EvrTagWriter(rds, eParams, minLength, reUseBD: reUseBD);

  /// Writes the [TagRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory TagWriter.toFile(TagRootDataset ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkFile(file, overwrite: overwrite);
    return new TagWriter(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new empty [File] from [path], writes the [TagRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory TagWriter.toPath(TagRootDataset ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    return new TagWriter(ds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  Uint8List writeFmi() => _evrWriter.writeFmi();

  /// Writes a [TagRootDataset] to a [Uint8List], then returns it.
  Bytes writeRootDataset() {
    if (!_evrWriter.isFmiWritten) _evrWriter.writeFmi();
    if (_evrWriter.rds.transferSyntax.isEvr) {
      return _evrWriter.writeRootDataset();
    } else {
      _ivrWriter = (doLogging)
          ? new IvrLoggingTagWriter.from(_evrWriter)
          : new IvrTagWriter.from(_evrWriter);
      return _ivrWriter.writeRootDataset();
    }
  }

  /// Writes the [RootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(TagRootDataset rds,
      {String path = '',
      EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    final writer = new TagWriter(rds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return writer.writeRootDataset();
  }

  /// Writes the [RootDataset] to a [Uint8List], then writes the
  /// [Uint8List] to the [File], and returns the [Uint8List].
  static Future<Bytes> writeFile(TagRootDataset ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool doAsync = true,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    (doAsync) ? await file.writeAsBytes(bytes.asUint8List()) : file
        .writeAsBytesSync
      (bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [TagRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Future<Bytes> writePath(TagRootDataset ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
        bool doAsync = true,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minLength: minLength,
        inputOffsets: inputOffsets,
        doAsync: doAsync,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }
}
