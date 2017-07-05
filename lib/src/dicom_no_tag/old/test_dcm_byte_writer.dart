// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/src/dicom_no_tag/old/dcm_byte_writer.dart';

class TestDcmByteWriter extends DcmByteWriter {
  static final Logger log = new Logger("DcmWriter", watermark: Severity.debug2);

  TestDcmByteWriter(
    RootByteDataset rootDS, {
    String path = "",
    TransferSyntax outputTS,
//    Endianness endianness = Endianness.LITTLE_ENDIAN,
    bool throwOnError = true,
    bool allowImplicitLittleEndian = true,
    bool addMissingPrefix = false,
    bool addMissingFMI = false,
    bool removeUndefinedLengths = false,
    bool reUseBD = true,
  })
      : super(rootDS,
            path: path,
            outputTS: outputTS,
//            endianness: endianness,
            throwOnError: throwOnError,
            allowImplicitLittleEndian: allowImplicitLittleEndian,
            addMissingPrefix: addMissingPrefix,
            addMissingFMI: addMissingFMI,
            removeUndefinedLengths: removeUndefinedLengths,
            reUseBD: reUseBD);

  //Urgent Move to TestByteWriter
// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// write successfully.
  void xWriteFmi(RootByteDataset rds) {
    if (!rds.hasFMI || !rds.hasSupportedTransferSyntax) return null;
    writeFMI();
  }

  Uint8List xWriteDataset(ByteDataset ds) {
    log.debugDown('$wbb writeDataset: isExplicitVR(${ds.isEVR})');
    var writer = new DcmByteWriter(ds);
    writer.writeDataset(ds);
    log.debugUp('$wee end writeDataset: isExplicitVR(${ds.isEVR})');
    return writer.bytes;
  }

  void xWritePublicElement(ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePGLength(ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateIllegal(int code, ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateCreator(ByteElement e) => writeElement(e);

  // External Interface for testing
  void xWritePrivateData(ByteElement pc, ByteElement e) => writeElement(e);
}
