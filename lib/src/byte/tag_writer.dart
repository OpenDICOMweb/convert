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
import 'package:dcm_convert/dcm.dart';

import 'dcm_writer.dart';

/// A [class] for writing a [RootTagDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntaxUid]es.
class TagWriter extends DcmWriter {
  /// The root [RootTagDataset] being written.
  final RootTagDataset _rootDS;

  /// The current [TagDataset].  This changes as Sequences are written.
  TagDataset _currentDS;

  /// Creates a new [TagWriter] where [wIndex] = 0.
  TagWriter(this._rootDS,
      {int bufferLength,
      String path = "",
      TransferSyntaxUid outputTS,
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

  /// Writes the [RootTagDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory TagWriter.toFile(RootTagDataset ds, File file,
      {int bufferLength = DcmWriter.defaultBufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = true,
      TransferSyntaxUid targetTS}) {
    checkFile(file, overwrite);
    return new TagWriter(ds,
        bufferLength: bufferLength,
        path: file.path,
        reUseBD: fast,
        outputTS: targetTS);
  }

  /// Creates a new empty [File] from [path], writes the [RootTagDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory TagWriter.toPath(RootTagDataset ds, String path,
      {int bufferLength = DcmWriter.defaultBufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = false,
      TransferSyntaxUid targetTS}) {
    checkPath(path);
    return new TagWriter(ds,
        bufferLength: bufferLength,
        path: path,
        reUseBD: fast,
        outputTS: targetTS);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].

  /// Returns the [RootTagDataset] being written.
  RootTagDataset get rootDS => _rootDS;

  TagDataset get currentDS => _currentDS;

  void set currentDS(TagDataset ds) => _currentDS = ds;

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  Uint8List writeFMI(bool hadFmi, {bool checkPreamble = false}) => dcmWriteFMI(hadFmi);

  /// Reads a [RootTagDataset] from [this], stores it in [rootDS],
  /// and returns it.
  Uint8List writeRootDataset({bool addMissingFMI = false}) =>
      dcmWriteRootDataset();

  /// Writes the [RootTagDataset] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootTagDataset ds,
      {int bufferLength,
      String path = "",
      bool fmiOnly: false,
      bool fast: true,
      TransferSyntaxUid outputTS,
      reUseBD = true}) {
    checkRootDataset(ds);
    var writer = new TagWriter(ds,
        bufferLength: bufferLength,
        path: path,
        reUseBD: reUseBD,
        outputTS: outputTS);
    return writer.writeRootDataset();
  }

  /// Writes the [RootTagDataset] to a [Uint8List], then writes the
  /// [Uint8List] to the [File], and returns the [Uint8List].
  static Uint8List writeFile(RootTagDataset ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = true,
      TransferSyntaxUid targetTS}) {
    checkFile(file, overwrite);
    var bytes = writeBytes(ds,
        bufferLength: bufferLength,
        path: file.path,
        reUseBD: fast,
        outputTS: targetTS);
    file.writeAsBytesSync(bytes);
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootTagDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Uint8List writePath(RootTagDataset ds, String path,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = false,
      TransferSyntaxUid targetTS}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: fmiOnly,
        fast: fast,
        targetTS: targetTS);
  }

  /// Creates a new empty [File] at [path], writes the [RootTagDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File],
  /// and returns the [Uint8List].
  static Uint8List writeFmi(RootTagDataset ds, String path,
      {int bufferLength,
      bool overwrite = false,
      fast = false,
      TransferSyntaxUid targetTS}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: true,
        fast: fast,
        targetTS: targetTS);
  }
}
