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

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:dcm_convert/src/binary/byte/writer/evr_byte_writer.dart';
import 'package:dcm_convert/src/binary/byte/writer/ivr_byte_writer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A [class] for writing a [RootDatasetByte] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter {
  final RootDataset rds;
  final String path;
  final bool overwrite;
  final EncodingParameters eParams;
  final TransferSyntax outputTS;
  final int minBDLength;
  final ElementOffsets inputOffsets;
  final bool reUseBD;
  final bool doLogging;
  final bool showStats;
  final EvrByteWriter _evrWriter;
  IvrByteWriter _ivrWriter;
  ElementOffsets outputOffsets;

  /// Creates a new [ByteWriter] where index = 0.
  ByteWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minBDLength = DcmWriterBase.defaultBufferLength,
      this.inputOffsets,
      this.reUseBD = true,
      this.doLogging = false,
      this.showStats = false})
      : _evrWriter = new EvrByteWriter(rds, eParams, minBDLength, reUseBD);

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(RootDatasetByte ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = false,
      bool showStats = false}) {
    checkFile(file, overwrite: overwrite);
    return new ByteWriter(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(RootDatasetByte ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = false,
      bool showStats = false}) {
    checkPath(path);
    return new ByteWriter(ds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Writes a [RootDatasetByte], and stores it in [rds], and returns it.
  Uint8List writeFmi() => _evrWriter.writeFmi();

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  Uint8List writeRootDataset(RootDataset rds) {
    if (!_evrWriter.isFmiWritten) writeFmi();

    if (_evrWriter.rds.transferSyntax.isEvr) {
      return _evrWriter.writeRootDataset(rds);
    } else {
      _ivrWriter = new IvrByteWriter(rds, eParams, minBDLength, reUseBD);
      return _ivrWriter.writeRootDataset(rds);
    }
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDatasetByte rds,
      {String path = '',
      EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = false,
      bool showStats = false}) {
    checkRootDataset(rds);
    final writer = new ByteWriter(rds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    return writer.writeRootDataset(rds);
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Future<Uint8List> writeFile(RootDatasetByte ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = false,
      bool showStats = false}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    await file.writeAsBytes(bytes);
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Future<Uint8List> writePath(RootDatasetByte ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = false,
      bool showStats = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }
}
