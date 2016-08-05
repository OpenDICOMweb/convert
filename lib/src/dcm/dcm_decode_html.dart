// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
library odw.sdk.convert.dcm.dcm_decoder_io;

import 'dart:html';
import 'dart:typed_data';

import 'package:logger/server.dart';
import 'package:path/path.dart' as path;

import 'package:odwhtml/file_io.dart';
import 'dcm_decoder.dart';

/// [DcmDecoder] reads DICOM SOP Instances and returns a [DatasetSop].
/// TODO: finish doc
class DcmDecoderHtml extends DcmDecoder {
  static final Logger log = new Logger("DcmEncoder");
  final File file;

  factory DcmDecoderHtml.fromFile(File file) {
    var filePath = path.normalize(file.name);

    log.debug('file length: ${bytes.length}, File: $filePath');
    return new DcmDecoderHtml._(bytes, 0, bytes.length, bytes.length, file);
  }

  DcmDecoderHtml._(Uint8List bytes, int readIndex, int writeIndex, int lengthInBytes, this.file)
      : super.internal(bytes, readIndex, writeIndex, lengthInBytes);

  String get name => path.normalize(file.name);

  Study decode() async {
    HtmlFile hFile = new HtmlFile(file);
    Uint8List bytes = await hFile.readAsBytes();
    var filePath = path.normalize(hFile.name);
    log.debug('file length: ${bytes.length}, File: $filePath');

    return new DcmDecoderHtml._(bytes, 0, bytes.length, bytes.length, filePath);
  }



}

DcmDecodeFile(File file, int start, int end) async {
  final Logger log = new Logger("DcmEncoder");

  HtmlFile hFile = new HtmlFile(file);
  Uint8List bytes = await hFile.readAsBytes();
  var filePath = path.normalize(hFile.name);
  log.debug('file length: ${bytes.length}, File: $filePath');


}


