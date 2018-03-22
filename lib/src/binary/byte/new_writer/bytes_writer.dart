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

import 'package:convert/src/binary/base/new_writer/subwriter.dart';
import 'package:convert/src/binary/bytes/new_writer/bytes_subwriter.dart';
import 'package:convert/src/utilities/element_offsets.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// A [class] for writing a [BDRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter {
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
  final EvrSubWriter _evrWriter;
  IvrSubWriter _ivrWriter;
  ElementOffsets outputOffsets;

  /// Creates a new [ByteWriter] where index = 0.
  ByteWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minLength = kDefaultWriteBufferLength,
      this.inputOffsets,
      this.reUseBD = true,
      this.doLogging = false,
      this.showStats = false})
      : _evrWriter = (doLogging)
            ? new LoggingByteEvrSubWriter(eParams, rds, inputOffsets)
            : new ByteEvrSubWriter(eParams, rds);

  /// Writes the [BDRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(BDRootDataset ds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
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
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new empty [File] from [path], writes the [BDRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(BDRootDataset ds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
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
        minLength: minLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  Bytes write() => writeRootDataset();
  Bytes writeFmi() => _evrWriter.writeFmi();

  /// Writes a [BDRootDataset] to a [Uint8List], then returns it.
  Bytes writeRootDataset() {
    if (!_evrWriter.isFmiWritten) _evrWriter.writeFmi();
    if (_evrWriter.rds.transferSyntax.isEvr) {
      return _evrWriter.writeRootDataset();
    } else {
      _ivrWriter = (doLogging)
          ? new LoggingByteIvrSubWriter.from(_evrWriter)
          : new ByteIvrSubWriter.from(_evrWriter);
      return _ivrWriter.writeRootDataset();
    }
  }

  /// Writes the [BDRootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(BDRootDataset rds,
      {String path = '',
      EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkRootDataset(rds);
    final writer = new ByteWriter(rds,
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

  /// Writes the [BDRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Bytes writeFile(BDRootDataset ds, File file,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
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
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
    file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [BDRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Bytes writePath(BDRootDataset ds, String path,
      {EncodingParameters eParams: EncodingParameters.kNoChange,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minLength,
      ElementOffsets inputOffsets,
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
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }
}
