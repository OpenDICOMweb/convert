// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/reader/reader.dart';
import 'package:dcm_convert/src/binary/byte/byte_reader.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';

/// External Interface for Testing Only!!!
class TestByteReader extends ByteReader {
  /// Creates a new [TestByteReader].
  TestByteReader(ByteData bd,
      {String path = '',
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = true})
      : super(bd, path: path, fmiOnly: fmiOnly, reUseBD: reUseBD);
  
// **** These methods should not be used in the code above ****

  /// Returns true if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi({bool checkPreamble = true, bool allowMissingPrefix = false}) {
    readFMI(checkPreamble: checkPreamble, allowMissingPrefix: allowMissingPrefix);
    if (!rootDS.hasFmi || !rootDS.hasSupportedTransferSyntax) return null;
    return rootDS.transferSyntax;
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
      rootDS.add(e);
      e = rootDS[e.code];
      assert(e == e);
    }
    return currentDS;
  }

  /// Reads only the File Meta Information (FMI), if present.
  static Dataset readBytes(Uint8List bytes, Dataset rootDS,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    final reader = new ByteReader(bd,
        path: path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        reUseBD: reUseBD,
        dParams: dParams);
    return reader.readRootDataset();
  }

  static RootDatasetByte readFile(File file, RootDatasetByte rootDS,
      {String path = '',
      bool async = true,
      bool fast = true,
      bool fmiOnly = false,
      bool reUseBD = true,
      DecodingParameters dParams = DecodingParameters.kNoChange}) {
    final bytes = file.readAsBytesSync();
    return readBytes(bytes, rootDS,
        path: file.path,
        async: async,
        fast: fast,
        fmiOnly: fmiOnly,
        reUseBD: reUseBD,
        dParams: dParams);
  }

  /// Reads only the File Meta Information (FMI), if present.
  static RootDatasetByte readFileFmiOnly(File file, RootDatasetByte rootDS,
          {String path = '',
          bool async = true,
          bool fast = true,
          bool fmiOnly = false,
          bool reUseBD = true,
          DecodingParameters dParams = DecodingParameters.kNoChange}) =>
      readFile(file, rootDS,
          path: path,
          async: async,
          fast: fast,
          fmiOnly: fmiOnly,
          reUseBD: reUseBD,
          dParams: dParams);
}
