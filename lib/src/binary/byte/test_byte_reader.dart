// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:dcm_convert/src/binary/byte/byte_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:element/byte_element.dart';
import 'package:uid/uid.dart';

/// External Interface for Testing Only!!!
class TestByteReader extends ByteReader {
  /// Creates a new [TestByteReader].
  TestByteReader(ByteData bd,
      {String path = '',
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : super(bd, path: path,  reUseBD: reUseBD);

// **** These methods should not be used in the code above ****

  /// Returns true if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi(RootDataset rds,
      {bool checkPreamble = true, bool allowMissingPrefix = false}) {
    readFmi(rds);
    if (!rds.hasFmi || !rds.hasSupportedTransferSyntax) return null;
    return rds.transferSyntax;
  }

  Element xReadPublicElement() => readElement();

  // External Interface for testing
  Element xReadPGLength() => readElement();

  // External Interface for testing
  Element xReadPrivateIllegal(int code) => readElement();

  // External Interface for testing
  Element xReadPrivateCreator() => readElement();

  // External Interface for testing
  Element xReadPrivateData(Element pc) => readElement();

  // Reads
  RootDatasetByte xReadDataset() {
    while (isReadable) {
      var e = readElement();
      rds.add(e);
      e = rds[e.code];
      assert(e == e);
    }
    return cds;
  }

  /// Reads only the File Meta Information (FMI), if present.
  static Dataset readBytes(Uint8List bytes, Dataset rds,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new ByteReader(bd,
        path: path,
        reUseBD: reUseBD,
        dParams: dParams);
    return reader.read();
  }

  static RootDatasetByte readFile(File file, RootDatasetByte rds,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bytes = file.readAsBytesSync();
    return readBytes(bytes, rds,
        path: file.path,
        async: async,
        fast: fast,

        reUseBD: reUseBD,
        dParams: dParams);
  }

  /// Reads only the File Meta Information (FMI), if present.
  static RootDatasetByte readFileFmiOnly(File file, RootDatasetByte rds,
          {String path = '',
          bool async = true,
          bool fast = true,
          bool fmiOnly = false,
          bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readFile(file, rds,
          path: path,
          reUseBD: reUseBD,
          dParams: dParams);
}
