// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:path/path.dart' as path;

const List<String> stdDcmExtensions = const <String>['.dcm', '', '.DCM'];

//TODO: what should default be?
const int kSmallDcmFileLimit = 376;

Bytes readPath(String fPath,
    { // TODO: change to true when async works
      bool doAsync = false,
    List<String> extensions = stdDcmExtensions,
    int minLength = kSmallDcmFileLimit,
    int maxLength}) {
  final ext = path.extension(fPath);
  if (!extensions.contains(ext)) return null;
  final f = new File(fPath);
  return readFile(f,
      doAsync: doAsync, minLength: minLength, maxLength: maxLength);
}

Bytes readFile(File f,
    { // TODO: change to true when async works
    bool doAsync = false,
    List<String> extensions = stdDcmExtensions,
    int minLength = kSmallDcmFileLimit,
    int maxLength}) {
  if (!f.existsSync() || !_checkLength(f, doAsync, minLength, maxLength))
    return null;
  try {
    final bytes = doAsync ? _readAsync(f) : _readSync(f);
    return new Bytes.fromTypedData(bytes);
  } on FileSystemException {
    return null;
  }
}

bool _checkLength(File f, bool doAsync, int min, int max) =>
  doAsync ? _checkLenAsync(f, min, max) : _checkLenSync(f, min, max);

Future<bool> _checkLenAsync(File f, int min, int max) async {
  assert(min >= 0 && max > min);
  final len = await f.length();
  final max0 = max ?? len;
  assert(min >= 0 && max0 > min);
  return (len >= min && len <= max0) ? true : false;
}

bool _checkLenSync(File f, int min, int max) {
  final len = f.lengthSync();
  final max0 = max ?? len;
  assert(min >= 0 && max0 > min);
  final v = (len >= min && len <= max0) ? true : false;
  return v;
}

Future<Uint8List> _readAsync(File f) async => await f.readAsBytes();
Uint8List _readSync(File f) => f.readAsBytesSync();
