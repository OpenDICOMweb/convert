// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/src/dcm/old/dcm_byte_reader.dart';

/// An internal class designed for testing DcmReader.
class TestDcmByteReader extends DcmByteReader {

  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  TestDcmByteReader(ByteData bd,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS,
      bool reUseBD = false})
      : super(bd,
            path: path,
            fmiOnly: fmiOnly,
            throwOnError: throwOnError,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS);

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory TestDcmByteReader.fromList(List<int> list, Dataset rootDS,
      {String path = "",
      bool fmiOnly = false,
      bool throwOnError = false,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new TestDcmByteReader(bd,
        path: path,
        fmiOnly: fmiOnly,
        throwOnError: throwOnError,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS);
  }

// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    readFmi(checkForPrefix);
    if (rootDS.length == 0) return null;
    var ts = rootDS.transferSyntax;
    if (!System.isSupportedTransferSyntax(ts))return null;
    return ts;
  }

  Element xReadPublicElement([bool isExplicitVR = true]) => readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPGLength([bool isExplicitVR = true]) => readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPrivateIllegal(int code, [bool isExplicitVR = true]) => readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPrivateCreator([bool isExplicitVR = true]) => readElement(isExplicitVR);

  // External Interface for testing
  Element xReadPrivateData(Element pc, [bool isExplicitVR = true]) {
    //  _TagMaker maker =
    //      (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
    return readElement(isExplicitVR);
  }

  // Used for testing. Reads any [Dataset], not just [RootDataset]s.
  Dataset xReadDataset([bool isExplicitVR = true]) {
    log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    while (isReadable) {
      var e = readElement(isExplicitVR);
      rootDS.add(e);
      e = rootDS[e.code];
      assert(e == e);
    }
    log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    return currentDS;
  }
}
