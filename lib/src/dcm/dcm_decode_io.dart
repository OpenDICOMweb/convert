// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.convert.dcm.dcm_decoder_io;

import 'dart:io';
import 'dart:typed_data';

import 'package:logger/server.dart';
import 'package:path/path.dart' as path;

import 'dcm_decoder.dart';

/// [DcmDecoder] reads DICOM SOP Instances and returns a [DatasetSop].
/// TODO: finish doc
class DcmDecoderIO extends DcmDecoder {
  static final Logger log = new Logger("DcmEncoder");
  final String filePath;

  factory DcmDecoderIO.fromFile(file) {
    if (file is! File) {
      log.error('The "file" parameter must be a String or File');
      return null;
    }
    var bytes = file.readAsBytesSync();
    var filePath = path.normalize(file.path);
    log.debug('file length: ${bytes.length}, File: $filePath');
    return new DcmDecoderIO._(bytes, 0, bytes.length, bytes.length, filePath);
  }

  DcmDecoderIO._(Uint8List bytes, int readIndex, int writeIndex, int lengthInBytes, this.filePath)
    : super.internal(bytes, readIndex, writeIndex, lengthInBytes);
}
