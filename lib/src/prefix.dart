// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:logger/logger.dart';

import 'package:encode/src/dicom/decoder_bytebuf.dart';

/// A DICOM File Prefix
class Prefix {
  static final log = new Logger("encode.prefix");
  final Uint8List preamble;
  final isAllZeros;
  final String name;

  // Create a DICOM file [Prefix].
  Prefix(Uint8List preamble, this.name)
      : isAllZeros = _allZeros(preamble),
        preamble = preamble;

  static bool isValidPrefix(String name) =>
      (validPrefixes[name] == null) ? false : true;

  static const Map<String, String> validPrefixes = const {
    "DICM": "DICOM File (PS3.10)",
    "DICOM-MD": "DICOM Metadata",
    "DICOM-BD": "DICOM Bulkdata"
  };

  // Read the 128-byte preamble to the DICOM File Format.
  static Uint8List readPreamble(buf) => buf.readUint8List(128);

  static Prefix readPrefix(DcmDecoderByteBuf buf) {
    var preamble = readPreamble(buf);
    var name = buf.readString(4);
    if (!isValidPrefix(name)) {
      buf.setReadIndex(0);
      return null;
    }
    log.info('Prefix.name: $name');
    return new Prefix(preamble, name);
  }

  static bool _allZeros(Uint8List preamble) {
    for(int i = 0; i < preamble.length; i++)
        if (preamble[i] != 0) return false;
    return true;
  }

  @override
  String toString() => 'DICOM File Prefix: preamble(all zeros: $isAllZeros, name: $name';
}