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
import 'package:dcm_convert/src/binary/byte/writer/evr_byte_log_writer.dart';
import 'package:dcm_convert/src/binary/byte/writer/ivr_byte_log_writer.dart';
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
  final TransferSyntax outputTS;
  final int minBDLength;
  final bool reUseBD;
  final EncodingParameters eParams;
  final ElementOffsets inputOffsets;
  final ElementOffsets outputOffsets;
  final EvrByteLogWriter evrWriter;

  IvrByteLogWriter _ivrWriter;

  /// Creates a new [ByteLogWriter] where index = 0.
  ByteLogWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minBDLength = DcmWriterBase.defaultBufferLength,
      this.reUseBD = true,
      this.inputOffsets})
      : evrWriter =
            new EvrByteLogWriter(rds, eParams, minBDLength, reUseBD, inputOffsets),
        outputOffsets = (inputOffsets == null) ? null : new ElementOffsets();

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteLogWriter.toFile(RootDatasetByte ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      bool reUseBD = false,
      ElementOffsets inputOffsets}) {
    checkFile(file, overwrite: overwrite);
    return new ByteLogWriter(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        reUseBD: reUseBD,
        inputOffsets: inputOffsets);
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteLogWriter.toPath(RootDatasetByte ds, String path,
      {int minBDLength,
      bool overwrite = false,
      TransferSyntax targetTS,
      ElementOffsets inputOffsets}) {
    checkPath(path);
    return new ByteLogWriter(ds,
        minBDLength: minBDLength,
        path: path,
        overwrite: overwrite,
        outputTS: targetTS,
        inputOffsets: inputOffsets);
  }

  /// Writes a [RootDatasetByte], and stores it in [rds], and returns it.
  Uint8List writeFmi() => evrWriter.writeFmi();

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  Uint8List writeRootDataset(RootDataset rds) {
    if (!evrWriter.isFmiWritten) writeFmi();

    if (evrWriter.rds.transferSyntax.isEvr) {
      return evrWriter.writeRootDataset(rds);
    } else {
      _ivrWriter = new IvrByteLogWriter.from(evrWriter);
      return _ivrWriter.writeRootDataset(rds);
    }
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDatasetByte rds,
      {int minBDLength,
      String path = '',
      bool reUseBD = true,
      TransferSyntax outputTS,
      ElementOffsets inputOffsets}) {
    checkRootDataset(rds);
    final writer = new ByteLogWriter(rds,
        minBDLength: minBDLength,
        path: path,
        overwrite: reUseBD,
        outputTS: outputTS,
        inputOffsets: inputOffsets);
    return writer.writeRootDataset(rds);
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Future<Uint8List> writeFile(RootDatasetByte ds, File file,
      {int minBDLength,
      bool overwrite = false,
      TransferSyntax targetTS,
      ElementOffsets inputOffsets}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        minBDLength: minBDLength,
        path: file.path,
        outputTS: targetTS,
        inputOffsets: inputOffsets);
    await file.writeAsBytes(bytes);
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Future<Uint8List> writePath(RootDatasetByte ds, String path,
      {int minBDLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = false,
      TransferSyntax targetTS,
      ElementOffsets inputOffsets}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        minBDLength: minBDLength,
        overwrite: overwrite,
        targetTS: targetTS,
        inputOffsets: inputOffsets);
  }
}
