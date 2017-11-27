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
import 'package:dcm_convert/src/binary/base/writer/dcm_writer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/io_utils.dart';
import 'package:element/byte_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';

/// A [class] for writing a [RootDatasetByte] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteDatasetWriter extends DcmWriter {
  /// Creates a new [ByteDatasetWriter] where [wIndex] = 0.
  ByteDatasetWriter(RootDatasetByte rds,
      {int bufferLength = DcmWriter.defaultBufferLength,
      String path = '',
      File file,
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool overwrite = true,
      EncodingParameters encoding = EncodingParameters.kNoChange,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets})
      : super(rds,
            length: bufferLength,
            path: path,
            outputTS: outputTS,
            reUseBuffer: overwrite,
            eParams: encoding,
            elementOffsetsEnabled: elementOffsetsEnabled,
            inputOffsets: inputOffsets);

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteDatasetWriter.toFile(RootDatasetByte ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = true,
      TransferSyntax targetTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    checkFile(file, overwrite: overwrite);
    return new ByteDatasetWriter(ds,
        bufferLength: bufferLength,
        path: file.path,
        overwrite: fast,
        outputTS: targetTS,
        elementOffsetsEnabled: elementOffsetsEnabled,
        inputOffsets: inputOffsets);
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteDatasetWriter.toPath(RootDatasetByte ds, String path,
      {int bufferLength,
      bool overwrite = false,
      TransferSyntax targetTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    checkPath(path);
    return new ByteDatasetWriter(ds,
        bufferLength: bufferLength,
        path: path,
        overwrite: overwrite,
        outputTS: targetTS,
        elementOffsetsEnabled: elementOffsetsEnabled,
        inputOffsets: inputOffsets);
  }

  @override
  ElementList get elements => rds.elements;

  @override
  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  @override
  Uint8List writeFmi() => super.writeFmi();

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  @override
  Uint8List write() => super.write();

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;

  /// Writes the [RootDatasetByte] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDatasetByte ds,
      {int bufferLength,
      String path = '',
      bool reUseBD = true,
      TransferSyntax outputTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    checkRootDataset(ds);
    final writer = new ByteDatasetWriter(ds,
        bufferLength: bufferLength,
        path: path,
        overwrite: reUseBD,
        outputTS: outputTS,
        elementOffsetsEnabled: elementOffsetsEnabled,
        inputOffsets: inputOffsets);
    return writer.write();
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Future<Uint8List> writeFile(RootDatasetByte ds, File file,
      {int bufferLength,
      bool overwrite = false,
      TransferSyntax targetTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        bufferLength: bufferLength,
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
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = false,
      TransferSyntax targetTS,
      bool elementOffsetsEnabled = true,
      ElementOffsets inputOffsets}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        targetTS: targetTS,
        elementOffsetsEnabled: elementOffsetsEnabled,
        inputOffsets: inputOffsets);
  }

  /// Creates a new empty [File] at [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File],
  /// and returns the [Uint8List].
  static Future<Uint8List> writeFmiPath(RootDatasetByte ds, String path,
      {int bufferLength,
      bool overwrite = false,
      bool fast = false,
      TransferSyntax targetTS}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        targetTS: targetTS);
  }
}
