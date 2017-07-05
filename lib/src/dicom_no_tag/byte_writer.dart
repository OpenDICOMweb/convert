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

//TODO: remove log.debug when working
//TODO: rewrite all comments to reflect current state of code

/// A [class] for writing a [Dataset] to a [Uint8List], and then
/// possibly writing it to a [File].
///
/// Supports encoding LITTLE ENDIAN [TransferSyntax]es.

class ByteWriter extends DcmWriter {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.info);

  //Urgent: this should grow and shrink adaptively.
  static const int defaultBufferLength = 200 * kMB;

  /// The root Dataset being written.
  final Dataset _rootDS;
  final int bdLength;

  /// The current dataset.  This changes as Sequences are written and
  /// [Items]s are pushed on and off the [dsStack].
  Dataset _currentDS;

  //TODO: Doc
  /// Creates a new [DcmWriter]  where [_wIndex] = [writeIndex] = 0.
  ByteWriter(this._rootDS, this.bdLength,
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

  Dataset get rootDS => _rootDS;

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  // **** DICOM encoding stuff ****

  // There are four [Element]s that might have an Undefined Length value
  // (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  // then it searches for the matching [kSequenceDelimitationItem] to
  // determine the length. Returns a [kUndefinedLength], which is used for
  // writeing the value field of these [Element]s. Returns an [SQ] [Element].

  /// writes an EVR or IVR Sequence. The _writeElementMethod detects Sequences.

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & writeElementExplicit
  /// Returns an [Item] or Fragment.

  /// Writes the [Dataset] to a [Uint8List]. Returns the [Uint8List].
  static Uint8List writeBytes(Dataset ds,
      {int bdLength = defaultBufferLength,
        String path = "",
      bool fmiOnly: false,
      bool fast: true,
      TransferSyntax outputTS,
      reUseBD = true}) {
    if (ds == null || ds.length == 0) throw new ArgumentError('Empty ' 'Empty Dataset: $ds');
    var length = (ds.vfLength == null) ? defaultBufferLength : ds.vfLength;
    var writer = new ByteWriter(ds, length, path: path, reUseBD: reUseBD, outputTS: outputTS);
    Uint8List bytes = writer.writeRootDataset();
    if (bytes == null || bytes.length < 256) throw 'Invalid bytes error: $bytes';
    log.info('wrote ${bytes.length} bytes to "$path"');
    return bytes;
  }

  /// Writes the [Dataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Uint8List writeFile(Dataset ds, File file,
      {int bdLength = defaultBufferLength, bool fmiOnly = false, fast = true, TransferSyntax
      targetTS}) {
    if (file == null) throw new ArgumentError('null File');
    var bytes = writeBytes(ds, path: file.path, reUseBD: fast, outputTS: targetTS);
    file.writeAsBytesSync(bytes);
    return bytes;
  }

  //Urgent: If the file exists what to do?
  /// Creates a new empty [File] at [path], writes the [Dataset] to a
  /// [Uint8List], and then writes the [Uint8List] to the [File].
  /// Returns the [Uint8List].
  static Uint8List writePath(Dataset ds, String path,
      {int bdLength = defaultBufferLength, bool fmiOnly = false, fast = false, TransferSyntax targetTS}) {
    if (path == null || path == "") throw new ArgumentError('Empty path: $path');
    return writeFile(ds, new File(path), fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
  }

  //Urgent: If the file exists what to do?
  /// Creates a new empty [File] at [path], writes the [Dataset] to a
  /// [Uint8List], and then writes the [Uint8List] to the [File].
  /// Returns the [Uint8List].
  static Uint8List writeFmi(Dataset ds, String path, {fast = false, TransferSyntax targetTS}) {
    if (path == null || path == "") throw new ArgumentError('Empty path: $path');
    return writeFile(ds, new File(path), fmiOnly: true, fast: fast, targetTS: targetTS);
  }
}
