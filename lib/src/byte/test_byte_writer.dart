// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'dart:async';
import 'dart:typed_data';

import 'package:dcm_convert/dcm.dart';
import 'package:system/core.dart';

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
  Future<Uint8List> xWriteFmi(RootByteDataset rds) {
    if (!rds.hadFmi || !rds.hasSupportedTransferSyntax) return null;
    return writeFMI(rds);
  }

  /// Returns a [Uint8List] containing the encoded [Dataset].
  void xWriteDataset(ByteDataset ds) {
    log.debug('$wbb writeDataset: isExplicitVR(${ds.isEVR})', 1);
    var writer = new ByteWriter(ds, bufferLength: ds.vfLength);
    writer.writeDataset(ds);
    log.debug('$wee end writeDataset: isExplicitVR(${ds.isEVR})', -1);
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
