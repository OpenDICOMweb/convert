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

import 'package:dataset/byte_dataset.dart';
import 'package:dataset/tag_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:element/tag_element.dart';
import 'package:uid/uid.dart';


import 'package:dcm_convert/src/binary/base/writer/dcm_writer.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A [class] for writing a [RootDatasetTag] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class TagWriter extends DcmWriter {
  /// Creates a new [TagWriter] where [wIndex] = 0.
  TagWriter(RootDatasetTag rds,
      {int bufferLength,
      String path = '',
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool allowImplicitLittleEndian = true,
      bool addMissingPrefix = false,
      bool allowMissingFMI = false,
      bool addMissingFMI = false,
      bool removeUndefinedLengths = false,
      bool reUseBD = true,
      EncodingParameters encoding})
      : assert(rds.transferSyntax != null),
			  super(rds,
            length: bufferLength,
            path: path,
            reUseBuffer: reUseBD,
            eParams: encoding);

  /// Writes the [RootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory TagWriter.toFile(RootDataset ds, File file,
      {int bufferLength = DcmWriter.defaultBufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = true,
      TransferSyntax targetTS}) {
    checkFile(file, overwrite: overwrite);
    return new TagWriter(ds,
        bufferLength: bufferLength, path: file.path, reUseBD: fast, outputTS: targetTS);
  }

  /// Creates a new empty [File] from [path], writes the [RootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory TagWriter.toPath(RootDataset ds, String path,
      {int bufferLength = DcmWriter.defaultBufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = false,
      TransferSyntax targetTS}) {
    checkPath(path);
    return new TagWriter(ds,
        bufferLength: bufferLength, path: path, reUseBD: fast, outputTS: targetTS);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].

  @override
  String get info =>
      '$runtimeType: rootDS: ${rds.info}, currentDS: ${cds.info}';

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;

  @override
  Uint8List writeFmi({bool cleanPreamble = true}) =>
      super.writeFmi();

  /// Reads a [RootDataset], and stores it in [rds],
  /// and returns it.
  @override
  Uint8List write() => super.write();

  /// Writes the [RootDataset] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDataset ds,
      {int bufferLength,
      String path = '',
      bool fmiOnly: false,
      bool fast: true,
      bool reUseBD = true,
      TransferSyntax outputTS}) {
    checkRootDataset(ds);
    final writer = new TagWriter(ds,
        bufferLength: bufferLength, path: path, reUseBD: reUseBD, outputTS: outputTS);
    return writer.write();
  }

  /// Writes the [RootDataset] to a [Uint8List], then writes the
  /// [Uint8List] to the [File], and returns the [Uint8List].
  static Uint8List writeFile(RootDatasetTag ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = true,
      TransferSyntax targetTS}) {
    checkFile(file, overwrite: overwrite);
    final bytes = writeBytes(ds,
        bufferLength: bufferLength, path: file.path, reUseBD: fast, outputTS: targetTS);
    file.writeAsBytesSync(bytes);
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Uint8List writePath(RootDatasetTag ds, String path,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = false,
      TransferSyntax targetTS}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: fmiOnly,
        fast: fast,
        targetTS: targetTS);
  }

  /// Creates a new empty [File] at [path], writes the [RootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File],
  /// and returns the [Uint8List].
  static Uint8List writeFmiPath(RootDatasetTag ds, String path,
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
