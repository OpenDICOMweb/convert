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
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/binary/base/writer/dcm_writer.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A [class] for writing a [ RootDatasetByte ] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class ByteWriter extends DcmWriter {
  /// The [ RootDatasetByte ] being written.
  final RootDatasetByte _rootDS;
  Dataset _currentDS;

  /// Creates a new [ByteWriter] where [wIndex] = 0.
  ByteWriter(RootDataset _rootDS,
      {int bufferLength = DcmWriter.defaultBufferLength,
      String path = '',
      File file,
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool reUseBD = true,
      EncodingParameters encoding = EncodingParameters.kNoChange})
      : _rootDS = _rootDS,
			  _currentDS = _rootDS,
			  super(_rootDS,
            bufferLength: bufferLength, path: path, reUseBD: reUseBD, eParams: encoding);

  /// Writes the [ RootDatasetByte ] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory ByteWriter.toFile(RootDatasetByte ds, File file,
      {int bufferLength,
      bool overwrite = false,
      bool fmiOnly = false,
      bool fast = true,
      TransferSyntax targetTS}) {
    checkFile(file, overwrite: overwrite);
    return new ByteWriter(ds,
        bufferLength: bufferLength, path: file.path, reUseBD: fast, outputTS: targetTS);
  }

  /// Creates a new empty [File] from [path], writes the [ RootDatasetByte ]
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
        bufferLength: bufferLength, path: path, reUseBD: fast, outputTS: targetTS);
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].

  /// Returns the [RootDataset] being written.
  @override
  RootDatasetByte get rootDS => _rootDS;

  @override
  Dataset get currentDS => _currentDS;
  @override
  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  Uint8List writeFMI({bool checkPreamble = false}) =>
      dcmWriteFMI(hadFmi: rootDS.hasFmi);

  /// Reads a [ RootDatasetByte ], stores it in [rootDS], and returns it.
  Uint8List writeRootDataset({bool allowMissingFMI = false}) => dcmWriteRootDataset();

  /// Writes the [ RootDatasetByte ] to a [Uint8List], and returns the [Uint8List].
  static Uint8List writeBytes(RootDatasetByte ds,
      {int bufferLength,
      String path = '',
      bool fmiOnly: false,
      bool fast: true,
      TransferSyntax outputTS,
      bool reUseBD = true}) {
    checkRootDataset(ds);
    final writer = new ByteWriter(ds,
        bufferLength: bufferLength, path: path, reUseBD: reUseBD, outputTS: outputTS);
    return writer.writeRootDataset();
  }

  /// Writes the [ RootDatasetByte ] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Uint8List writeFile(RootDatasetByte ds, File file,
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

  /// Creates a new empty [File] from [path], writes the [ RootDatasetByte ]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Uint8List writePath(RootDatasetByte ds, String path,
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

  /// Creates a new empty [File] at [path], writes the [ RootDatasetByte ]
  /// to a [Uint8List], then writes the [Uint8List] to the [File],
  /// and returns the [Uint8List].
  static Uint8List writeFmi(RootDatasetByte ds, String path,
      {int bufferLength, bool overwrite = false, bool fast = false}) {
    checkPath(path);
    return writeFile(ds, new File(path),
        bufferLength: bufferLength,
        overwrite: overwrite,
        fmiOnly: true,
        fast: fast);
  }
}
