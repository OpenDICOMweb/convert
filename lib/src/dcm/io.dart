// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.io.dcm.read;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

//TODO: move this whole file to sdk/io when working

class DcmData {
  final File file;
  final Uint8List data;

  DcmData(this.file, this.data);

  DcmData.fromFile(File file)
      : file = file,
        data = readDcmFileSync(file);

  static Future<DcmData> retrieve(var path) async {
    File file = toFile(path);
    Uint8List data = await file.readAsBytes();
    return new DcmData(file, data);
  }
}
/// Returns a [File] if possible.
File toFile(path) {
  if (path is File) return path;
  if (path is String) return new File(path);
  if (path is Uri) new File.fromUri(path);
  return new File(path.toString());
}

Future<Uint8List> readDcmFile(var path) async {
  File file = toFile(path);
  return await file.readAsBytes();
}

Uint8List readDcmFileSync(var path) {
  File file = toFile(path);
  return file.readAsBytesSync();
}

/* Fix:
Future<Uint8List> readDcmFileList(List pathList) async {
  for (var path in pathList) {
    File file = toFile(path);
    return await file.readAsBytes();
  }
}

Uint8List readDcmFileListSync(List pathList) {
  File file = toFile(pathList);
  return file.readAsBytesSync();
}
*/