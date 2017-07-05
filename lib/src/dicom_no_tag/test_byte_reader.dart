// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:dcm_convert/src/dicom_no_tag/byte_reader.dart';
import 'package:dictionary/dictionary.dart';

/// External Interface for Testing Only!!!
class TestByteReader extends ByteReader {
  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  TestByteReader(ByteData bd,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : super(bd,
            path: path,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS,
            reUseBD: reUseBD);

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  factory TestByteReader.fromBytes(Uint8List bytes,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true}) {
    var bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    return new ByteReader(bd,
        path: path,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS,
        reUseBD: reUseBD);
  }

// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
     bool hadFmi = readFMI(checkForPrefix);
    if (!hadFmi || !rootDS.hasFMI || !rootDS.hasSupportedTransferSyntax) return null;
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

  /// Reads only the File Meta Information ([FMI], if present.
  static Dataset readBytes(Uint8List bytes, Dataset rootDS,
      {String path = "", bool fmiOnly = false, TransferSyntax targetTS}) {
    ByteData bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    ByteReader reader = new ByteReader(bd, path: path, fmiOnly: fmiOnly, targetTS: targetTS);
    return reader.readRootDataset();
  }

  static RootDataset readFile(File file, RootDataset rootDS,
      {bool fmiOnly = false, TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes, rootDS, path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  /// Reads only the File Meta Information ([FMI], if present.
  static RootDataset readFileFmiOnly(File file, RootDataset rootDS,
      {String path = "", TransferSyntax targetTS}) =>
      readFile(file, rootDS, fmiOnly: true, targetTS: targetTS);
}
