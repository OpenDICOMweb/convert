// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/byte/read_bytes.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/file_utils.dart';
import 'package:dcm_convert/src/io_utils.dart';


Future<Uint8List> readFileFast(File f, {bool fast = true}) async =>
	(fast) ? await f.readAsBytes() : 		f.readAsBytesSync();

Future<Uint8List> readFileAsync(File f) async {
  final bytes = await f.readAsBytes();
  print(bytes.length);
  return bytes;
}

Uint8List readFileSync(File f) => f.readAsBytesSync();

//Urgent make sure garbage is not being retained
//Urgent Test async
Future<bool> doReadByteFile(File f,
    {bool throwOnError = false, bool fast = true, bool isAsync = true}) async {
  system.log.level = Level.error;
  //TODO: improve output
//  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);
  final cPath = cleanPath(f.path);


  try {
	  final  bytes = await readDcmPath(cPath);
	  if (bytes == null) return false;
	  final bd = bytes.buffer.asByteData();
	  final reader0 = new ByteDatasetReader(bd);
	  final rds0 = reader0.read();
    if (rds0 == null) {
      log.info0('Unreadable File: $cPath');
      return false;
    }
    if (rds0.parseInfo == null) {
      log.info0('Bad File - No ParseInfo: $cPath');
      return false;
    }
    if (rds0.parseInfo != null) log.debug('$pad    ${rds0.parseInfo.info}');

// TODO: move into dataset.warnings.
	  final e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');

    if (rds0 != null) log.info0('$pad Success!');
    return true;
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $cPath');
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
    return false;
  }
  return false;
}
