// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dictionary/dictionary.dart';

import 'byte_writer.dart';

/// A class designed for testing [ByteWriter].
/// Note: This class should not be used in production code.
class TestByteWriter extends ByteWriter {
  /// Creates a new [TestByteWriter].
  TestByteWriter(RootByteDataset rootDS,
      {int length,
      String path = "",
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool reUseBD = true,
      EncodingParameters encoding})
      : super(rootDS,
            bufferLength: length,
            path: path,
            outputTS: outputTS,
            throwOnError: throwOnError,
            reUseBD: reUseBD,
            encoding: encoding);

  /// Returns a [Uint8List] containing the encoded FMI.
  Uint8List xWriteFmi(ByteDataset rds) {
    if (!rds.hasFMI || !rds.hasSupportedTransferSyntax) return null;
    return writeFMI();
  }

  /// Returns a [Uint8List] containing the encoded [Dataset].
  Uint8List xWriteDataset(ByteDataset ds) {
    log.debugDown('$wbb writeDataset: isExplicitVR(${ds.isEVR})');
    var writer = new ByteWriter(ds, bufferLength: ds.vfLength);
    var bytes = writer.writeDataset(ds);
    log.debugUp('$wee end writeDataset: isExplicitVR(${ds.isEVR})');
    return bytes;
  }

  /// Writes an element to the [currentDS].
  void xWritePublicElement(ByteElement e) => xWriteElement(e);

/* Flush or Test if needed.
  // External Interface for testing
  void xWritePGLength(ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateIllegal(int code, ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateCreator(ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateData(ByteElement pc, ByteElement e) => writeElement(e);
*/

}
