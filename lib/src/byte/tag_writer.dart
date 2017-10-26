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

import 'package:dataset/tag_dataset.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/byte_reader.dart';
import 'dcm_writer.dart';

/// A [class] for writing a [RootDatasetTag] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class TagWriter extends DcmWriter {
  /// The root [RootDatasetTag] being written.
  final RootDataset _rootDS;

  /// The current [Dataset].  This changes as Sequences are written.
  Dataset _currentDS;

  /// Creates a new [TagWriter] where [wIndex] = 0.
  TagWriter(this._rootDS,
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
      : super(_rootDS,
            bufferLength: bufferLength,
            path: path,
            outputTS: outputTS,
            throwOnError: throwOnError,
            reUseBD: reUseBD,
            encoding: encoding) {
    assert(_rootDS.transferSyntax != null);
  }

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

  /// Returns the [RootDataset] being written.
  @override
  RootDataset get rootDS => _rootDS;

  @override
  Dataset get currentDS => _currentDS;

  @override
  set currentDS(Dataset ds) => _currentDS = ds;

  @override
  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  Uint8List writeFMI({bool hadFmi, bool addPreamble = false}) =>
      dcmWriteFMI(hadFmi: hadFmi);

  /// Reads a [RootDataset] from [this], stores it in [rootDS],
  /// and returns it.
  Uint8List writeRootDataset({bool addMissingFMI = false}) => dcmWriteRootDataset();

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
    return writer.writeRootDataset();
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
  static Uint8List writeFmi(RootDatasetTag ds, String path,
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
