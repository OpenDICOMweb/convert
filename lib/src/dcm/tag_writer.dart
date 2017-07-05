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

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'dcm_writer.dart';

/// A [class] for writing a [RootTagDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class TagWriter extends DcmWriter {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.info);

  /// The root [RootTagDataset] being written.
  final RootTagDataset _rootDS;

  /// The current [TagDataset].  This changes as Sequences are written.
  TagDataset _currentDS;

  /// Creates a new [TagWriter] where [wIndex] = 0.
  TagWriter(this._rootDS, int bdLength,
      {String path = "",
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool allowImplicitLittleEndian = true,
      bool addMissingPrefix = false,
      bool allowMissingFMI = false,
      bool addMissingFMI = false,
      bool removeUndefinedLengths = false,
      bool reUseBD = true})
      : super(bdLength,
            path: path,
            outputTS: outputTS,
            throwOnError: throwOnError,
            allowImplicitLittleEndian: allowImplicitLittleEndian,
            addMissingPrefix: addMissingPrefix,
            allowMissingFMI: allowMissingFMI,
            addMissingFMI: addMissingFMI,
            removeUndefinedLengths: removeUndefinedLengths,
            reUseBD: reUseBD);

  /// Returns the [RootTagDataset] being written.
  RootTagDataset get rootDS => _rootDS;

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Writes the [RootTagDataset] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootTagDataset ds,
      {int bdLength,
      String path = "",
      bool fmiOnly: false,
      bool fast: true,
      TransferSyntax outputTS,
      reUseBD = true}) {
    DcmWriter.checkRootDataset(ds);
    var writer = new TagWriter(ds, bdLength,
        path: path, reUseBD: reUseBD, outputTS: outputTS);
    return writer.writeRootDataset();
  }

  /// Writes the [RootTagDataset] to a [Uint8List], then writes the
  /// [Uint8List] to the [File], and returns the [Uint8List].
  static Uint8List writeFile(RootTagDataset ds, File file,
      {int bdLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = true,
      TransferSyntax targetTS}) {
    DcmWriter.checkFile(file, overwrite);
    var bytes = writeBytes(ds,
        bdLength: bdLength, path: file.path, reUseBD: fast, outputTS: targetTS);
    file.writeAsBytesSync(bytes);
    return bytes;
  }

  /// Creates a new empty [File] from [path], writes the [RootTagDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Uint8List writePath(RootTagDataset ds, String path,
      {int bdLength,
      bool overwrite = false,
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    DcmWriter.checkPath(path);
    return writeFile(ds, new File(path),
        bdLength: bdLength,
        overwrite: overwrite,
        fmiOnly: fmiOnly,
        fast: fast,
        targetTS: targetTS);
  }

  /// Creates a new empty [File] at [path], writes the [RootTagDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File],
  /// and returns the [Uint8List].
  static Uint8List writeFmi(RootTagDataset ds, String path,
      {int bdLength,
      bool overwrite = false,
      fast = false,
      TransferSyntax targetTS}) {
    DcmWriter.checkPath(path);
    return writeFile(ds, new File(path),
        bdLength: bdLength,
        overwrite: overwrite,
        fmiOnly: true,
        fast: fast,
        targetTS: targetTS);
  }
}
