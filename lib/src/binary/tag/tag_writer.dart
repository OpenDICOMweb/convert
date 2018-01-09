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

import 'package:dataset/bd_dataset.dart';
import 'package:dataset/tag_dataset.dart';
import 'package:element/element.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/dcm_writer_base.dart';
import 'package:dcm_convert/src/binary/base/writer/evr_writer.dart';
import 'package:dcm_convert/src/binary/base/writer/ivr_writer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';
import 'package:dcm_convert/src/io_utils.dart';

/// A [class] for writing a [TagRootDataset] to a [Uint8List],
/// and then possibly writing it to a [File]. Supports encoding
/// all LITTLE ENDIAN [TransferSyntax]es.
class TagWriter extends DcmWriterBase {
  final RootDataset rds;
  final String path;
  final bool overwrite;
  final EncodingParameters eParams;
  final TransferSyntax outputTS;
  final int minBDLength;
  final ElementOffsets inputOffsets;
  final bool reUseBD;
  final bool doLogging;
  final bool showStats;
  final EvrWriter _evrWriter;
  IvrWriter _ivrWriter;
  ElementOffsets outputOffsets;

/*
  /// Creates a new [TagWriter] where [wIndex] = 0.
  TagWriter(TagRootDataset rds,
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
*/

  /// Creates a new [TagWriter] where index = 0.
  TagWriter(this.rds,
      {this.path = '',
      this.eParams = EncodingParameters.kNoChange,
      this.outputTS,
      this.overwrite = false,
      this.minBDLength = DcmWriterBase.defaultBufferLength,
      this.inputOffsets,
      this.reUseBD = true,
      this.doLogging = true,
      this.showStats = false})
      : _evrWriter = (doLogging)
            ? new EvrLogWriterBD(rds, eParams, minBDLength, reUseBD, inputOffsets)
            : new EvrTagWriter(rds, eParams, minBDLength, reUseBD);

  /// Writes the [BDRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  factory TagWriter.toFile(BDRootDataset ds, File file,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkFile(file, overwrite: overwrite);
    return new TagWriter(ds,
        path: file.path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  /// Creates a new empty [File] from [path], writes the [BDRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  factory TagWriter.toPath(BDRootDataset ds, String path,
      {EncodingParameters eParams,
      TransferSyntax outputTS,
      bool overwrite = false,
      int minBDLength,
      ElementOffsets inputOffsets,
      bool reUseBD = false,
      bool doLogging = true,
      bool showStats = false}) {
    checkPath(path);
    return new TagWriter(ds,
        path: path,
        eParams: eParams,
        outputTS: outputTS,
        overwrite: overwrite,
        minBDLength: minBDLength,
        inputOffsets: inputOffsets,
        reUseBD: reUseBD,
        doLogging: doLogging,
        showStats: showStats);
  }

  Uint8List writeFmi() => _evrWriter.writeFmi();

  /// Reads a [BDRootDataset], and stores it in [rds], and returns it.
  Uint8List writeRootDataset() {
    if (!_evrWriter.isFmiWritten) _evrWriter.writeFmi();

    if (_evrWriter.rds.transferSyntax.isEvr) {
      return _evrWriter.writeRootDataset(rds);
    } else {
      _ivrWriter = (doLogging)
                   ? new IvrLogWriterBD.from(_evrWriter)
                   : new IvrWriterBD.from(_evrWriter);
      return _ivrWriter.writeRootDataset(rds);
    }
  }

  // The following Getters and Setters provide the correct [Type]s
  // for [rootDS] and [currentDS].

  @override
  String get info => '$runtimeType: rootDS: ${rds.info}, currentDS: ${cds.info}';

  @override
  String elementInfo(Element e) => (e == null) ? 'Element e = null' : e.info;

  @override
  String itemInfo(Item item) => (item == null) ? 'Item item = null' : item.info;

  @override
  Uint8List writeFmi({bool cleanPreamble = true}) => super.writeFmi();

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
  static Uint8List writeFile(TagRootDataset ds, File file,
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
  static Uint8List writePath(TagRootDataset ds, String path,
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
  static Uint8List writeFmiPath(TagRootDataset ds, String path,
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
