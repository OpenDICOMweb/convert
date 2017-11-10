// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

const List<String> stdDcmExtensions = const <String>['.dcm', ''];

//TODO: what should default be?
const int kSmallDcmFileLimit = 376;

Future<Uint8List> readDcmPath(String fPath,
    [List<String> extensions = stdDcmExtensions,
    int sizeLimit = kSmallDcmFileLimit]) async {
  final ext = path.extension(fPath);
  if (!extensions.contains(ext)) return null;
  final f = new File(fPath);
  return readDcmFile(f, sizeLimit);
}

Future<Uint8List> readDcmFile(File f, [int sizeLimit = kSmallDcmFileLimit]) async {
  Uint8List bytes;
  if (f.existsSync() && await f.length() > kSmallDcmFileLimit) {
    try {
      bytes = await f.readAsBytes();
    } on FileSystemException {
      return null;
    }
    return (bytes.length > kSmallDcmFileLimit) ? bytes : null;
  }
  return null;
}

Uint8List readDcmPathSync(String fPath,
    [List<String> extensions = stdDcmExtensions, int sizeLimit = kSmallDcmFileLimit]) {
  final ext = path.extension(fPath);
  if (!extensions.contains(ext)) return null;
  final f = new File(fPath);
  return readDcmFileSync(f, sizeLimit);
}

Uint8List readDcmFileSync(File f, [int sizeLimit = kSmallDcmFileLimit]) {
  if (f.existsSync() && f.lengthSync() > kSmallDcmFileLimit) {
    try {
      final bytes = f.readAsBytesSync();
      return (bytes.length > kSmallDcmFileLimit) ? bytes : null;
    } on FileSystemException {
      return null;
    }
  }
}
