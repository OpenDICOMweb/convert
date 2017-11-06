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
import 'package:element/byte_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/dcm_writer.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A [class] for writing a [RootDatasetByte] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter extends DcmWriter {
  /// Creates a new [ByteWriter] where [wIndex] = 0.
  ByteWriter(RootDatasetByte rds,
      {int bufferLength = DcmWriter.defaultBufferLength,
      String path = '',
      File file,
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool reUseBuffer = true,
      EncodingParameters encoding = EncodingParameters.kNoChange})
      : super(rds,
            length: bufferLength,
            path: path,
            outputTS: outputTS,
            reUseBuffer: reUseBuffer,
            eParams: encoding);

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(RootDatasetByte ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = true,
      TransferSyntax targetTS}) {
    checkFile(file, overwrite: overwrite);
    return new ByteWriter(ds,
        bufferLength: bufferLength, path: file.path, reUseBuffer: fast, outputTS: targetTS);
  }

  /// Creates a new empty [File] from [path], writes the [RootDatasetByte]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(RootDatasetByte ds, String path,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = false,
      TransferSyntax targetTS}) {
    checkPath(path);
    return new ByteWriter(ds,
        bufferLength: bufferLength, path: path, reUseBuffer: fast, outputTS: targetTS);
  }

  @override
  ElementList get elements => rds.elements;

  @override
  String get info =>
      '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  @override
  Uint8List writeFmi() => super.writeFmi();

  /// Reads a [RootDatasetByte], and stores it in [rds], and returns it.
  @override
  Uint8List write({bool allowMissingFMI = false}) => super.write();

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;

  /// Writes the [RootDatasetByte] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDatasetByte ds,
      {int bufferLength,
      String path = '',
      bool fmiOnly: false,
      bool fast: true,
	      bool reUseBD = true,
      TransferSyntax outputTS
      }) {
    checkRootDataset(ds);
    final writer = new ByteWriter(ds,
        bufferLength: bufferLength, path: path, reUseBuffer: reUseBD, outputTS: outputTS);
    return writer.write();
  }

  /// Writes the [RootDatasetByte] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Future<Uint8List> writeFile(RootDatasetByte ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = true,
      TransferSyntax targetTS}) async {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        bufferLength: bufferLength, path: file.path, reUseBD: fast, outputTS: targetTS);
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
      TransferSyntax targetTS})  {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: fmiOnly,
        fast: fast,
        targetTS: targetTS);
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
        fmiOnly: true,
        fast: fast,
        targetTS: targetTS);
  }
}




