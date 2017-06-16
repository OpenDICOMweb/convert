// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:convertX/src/dicom_no_tag/dcm_byte_reader.dart';


/// External Interface for Testing Only!!!
class TestByteReader extends DcmByteReader {
  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  TestByteReader(ByteData bd,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS})
      : super(bd,
            path: path,
            throwOnError: throwOnError,
            allowILEVR: allowILEVR,
            allowMissingPrefix: allowMissingFMI,
            targetTS: targetTS);

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  factory TestByteReader.fromBytes(Uint8List bytes,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    var bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    return new DcmByteReader(bd,
        path: path,
        throwOnError: throwOnError,
        allowILEVR: allowILEVR,
        allowMissingPrefix: allowMissingFMI,
        targetTS: targetTS);
  }


// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (!hadFMI || !rootDS.hasFMI || !rootDS.hasSupportedTransferSyntax)
      return null;
    return rootDS.transferSyntax;
  }

  ByteElement xReadPublicElement() => readElement();

  // External Interface for testing
  ByteElement xReadPGLength() => readElement();

  // External Interface for testing
  ByteElement xReadPrivateIllegal(int code) => readElement();

  // External Interface for testing
  ByteElement xReadPrivateCreator() => readElement();

  // External Interface for testing
  ByteElement xReadPrivateData(ByteElement pc) => readElement();

  // Reads
  ByteDataset xReadDataset() {
    while (isReadable) {
      var e = readElement();
      rootDS.add(e);
      e = rootDS[e.code];
      assert(e == e);
    }
    return currentDS;
  }


  static RootByteDataset readBytes(Uint8List bytes,
      {String path: "",
        bool fmiOnly = false,
        fast = true,
        TransferSyntax targetTS}) {
    if (bytes == null) throw new ArgumentError('readBytes: $bytes');
    if (bytes.length < 256) {
      return null;
    }
    DcmByteReader reader =
    new DcmByteReader.fromBytes(bytes, path: path, targetTS: targetTS);
    if (fmiOnly) return (reader.hadFMI) ? reader.rootDS : null;
    return reader.readRootDataset();
  }
}
