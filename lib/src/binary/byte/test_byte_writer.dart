// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/byte/byte_writer.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

/// A class designed for testing [ByteWriter].
/// Note: This class should not be used in production code.
class TestByteWriter extends ByteWriter {
  /// Creates a new [TestByteWriter].
  TestByteWriter(RootDatasetByte rootDS,
      {int length,
      String path = '',
      TransferSyntax outputTS,
      bool throwOnError = true,
      bool reUseBD = true,
      EncodingParameters encoding})
      : super(rootDS,
            bufferLength: length,
            path: path,
            outputTS: outputTS,
            throwOnError: throwOnError,
            reUseBuffer: reUseBD,
            encoding: encoding);

  /// Returns a [Uint8List] containing the encoded FMI.
  Uint8List xWriteFmi(RootDatasetByte rds) {
    if (!rds.hasFmi || !rds.hasSupportedTransferSyntax) return null;
    return super.writeFmi();
  }

  /// Returns a [Uint8List] containing the encoded [Dataset].
  void xWriteDataset(RootDatasetByte ds) {
    log.debug('${wb.wbb} writeDataset: isExplicitVR(${ds.isEvr})', 1);
    new ByteWriter(ds, bufferLength: ds.length)..writeDataset(ds, eParams);
    log.debug('${wb.wee} end writeDataset: isExplicitVR(${ds.isEvr})', -1);
  }

  /// Writes an element to the [cds].
  void xWritePublicElement(Element e) => xWriteElement(e);

/* Flush or Test if needed.
  // External Interface for testing
  void xWritePGLength(Element e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateIllegal(int code, Element e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateCreator(Element e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateData(Element pc, Element e) => writeElement(e);
*/

}
