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
import 'package:dictionary/dictionary.dart';

import 'dcm_writer.dart';

/// A [class] for writing a [RootByteDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter extends DcmWriter {
  /// The [RootByteDataset] being written.
  final RootByteDataset _rootDS;

  /// The current [ByteDataset].  This changes as Sequences are written.
  ByteDataset _currentDS;

  /// Creates a new [ByteWriter] where [wIndex] = 0.
  ByteWriter(this._rootDS,
      {int bufferLength,
      String path = "",
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool allowImplicitLittleEndian = true,
      bool addMissingPrefix = false,
      bool allowMissingFMI = false,
      bool addMissingFMI = false,
      bool removeUndefinedLengths = false,
      bool reUseBD = true})
      : super(
            bufferLength: bufferLength,
            path: path,
            outputTS: outputTS,
            throwOnError: throwOnError,
            allowImplicitLittleEndian: allowImplicitLittleEndian,
            addMissingPrefix: addMissingPrefix,
            allowMissingFMI: allowMissingFMI,
            addMissingFMI: addMissingFMI,
            removeUndefinedLengths: removeUndefinedLengths,
            reUseBD: reUseBD);

  /// Writes the [RootByteDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(RootByteDataset ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = true,
      TransferSyntax targetTS}) {
    DcmWriter.checkFile(file, overwrite);
    return new ByteWriter(ds,
        bufferLength: bufferLength,
        path: file.path,
        reUseBD: fast,
        outputTS: targetTS);
  }

  /// Creates a new empty [File] from [path], writes the [RootByteDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory ByteWriter.toPath(RootByteDataset ds, String path,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    DcmWriter.checkPath(path);
    return new ByteWriter(ds,
        bufferLength: bufferLength,
        path: path,
        reUseBD: fast,
        outputTS: targetTS);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].

  /// Returns the [RootTagDataset] being written.
  RootByteDataset get rootDS => _rootDS;

  ByteDataset get currentDS => _currentDS;

  void set currentDS(ByteDataset ds) => _currentDS = ds;

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  Uint8List writeFMI([bool checkPreamble = false]) => dcmWriteFMI();

  /// Reads a [RootByteDataset] from [this], stores it in [rootDS],
  /// and returns it.
  Uint8List writeRootDataset({bool allowMissingFMI = false}) =>
      dcmWriteRootDataset();

  /// Writes the [RootByteDataset] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootByteDataset ds,
      {int bufferLength,
      String path = "",
      bool fmiOnly: false,
      bool fast: true,
      TransferSyntax outputTS,
      reUseBD = true}) {
    DcmWriter.checkRootDataset(ds);
    var writer = new ByteWriter(ds,
        bufferLength: bufferLength,
        path: path,
        reUseBD: reUseBD,
        outputTS: outputTS);
    return writer.writeRootDataset();
  }

  /// Writes the [RootByteDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Uint8List writeFile(RootByteDataset ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = true,
      TransferSyntax targetTS}) {
    DcmWriter.checkFile(file, overwrite);
    var bytes = writeBytes(ds,
        bufferLength: bufferLength,
        path: file.path,
        reUseBD: fast,
        outputTS: targetTS);
    file.writeAsBytesSync(bytes);
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootByteDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Uint8List writePath(RootByteDataset ds, String path,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    DcmWriter.checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: fmiOnly,
        fast: fast,
        targetTS: targetTS);
  }

  /// Creates a new empty [File] at [path], writes the [RootByteDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File],
  /// and returns the [Uint8List].
  static Uint8List writeFmi(RootByteDataset ds, String path,
      {int bufferLength,
      bool overwrite = false,
      fast = false,
      TransferSyntax targetTS}) {
    DcmWriter.checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: true,
        fast: fast,
        targetTS: targetTS);
  }
}
