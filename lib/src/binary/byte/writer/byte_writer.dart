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
  final bool reUseBD;
  final EvrByteWriter evrWriter;

  IvrByteWriter _ivrWriter;

  /// Creates a new [ByteWriter] where index = 0.
  ByteWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minBDLength = DcmWriterBase.defaultBufferLength,
      this.reUseBD = true})
      : evrWriter = new EvrByteWriter(rds, eParams, minBDLength, reUseBD);


  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(RootDatasetByte ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      bool reUseBD = false}) {
    checkFile(file, overwrite: overwrite);
    return new ByteWriter(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        reUseBD: reUseBD);
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(RootDatasetByte ds, String path,
      {int minBDLength,
      bool overwrite = false,
      TransferSyntax targetTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    checkPath(path);
    return new ByteWriter(ds,
        minBDLength: minBDLength,
        path: path,
        overwrite: overwrite,
        outputTS: targetTS);
  }

  /// Writes a [RootDatasetByte], and stores it in [rds], and returns it.
  Uint8List writeFmi() => evrWriter.writeFmi();

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  Uint8List writeRootDataset(RootDataset rds) {
    if (!evrWriter.isFmiWritten) writeFmi();

    if (evrWriter.rds.transferSyntax.isEvr) {
      return evrWriter.writeRootDataset(rds);
    } else {
      _ivrWriter = new IvrByteWriter(rds, eParams, minBDLength, reUseBD);
      return _ivrWriter.writeRootDataset(rds);
    }
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDatasetByte rds,
      {int minBDLength,
      String path = '',
      bool reUseBD = true,
      TransferSyntax outputTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    checkRootDataset(rds);
    final writer = new ByteWriter(rds,
        minBDLength: minBDLength,
        path: path,
        overwrite: reUseBD,
        outputTS: outputTS);
    return writer.writeRootDataset(rds);
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Future<Uint8List> writeFile(RootDatasetByte ds, File file,
      {int minBDLength,
      bool overwrite = false,
      TransferSyntax targetTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        minBDLength: minBDLength,
        path: file.path,
        outputTS: targetTS,
        elementOffsetsEnabled: elementOffsetsEnabled,
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
      bool elementOffsetsEnabled = true}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        minBDLength: minBDLength,
        overwrite: overwrite,
        targetTS: targetTS,
        elementOffsetsEnabled: elementOffsetsEnabled);
  }
}
