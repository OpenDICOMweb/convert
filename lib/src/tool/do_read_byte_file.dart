// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/dcm.dart';
import 'package:system/system.dart';

Future _readFileAsync(File f) async {
  var bytes = await f.readAsBytes();
  print(bytes.length);
  return bytes;
}

Uint8List _readFileSync(File f)  => f.readAsBytesSync();


bool doReadByteFile(File f, [bool throwOnError = false, bool fast = true]) {
  System.log.level = Level.error;
  //TODO: improve output
//  var n = getPaddedInt(fileNumber, width);
  var pad = "".padRight(5);
  var path = cleanPath(f.path);

  try {
    var bytes = _readFileSync(f);
    ByteData bd = bytes.buffer.asByteData();
    var reader0 = new ByteReader(bd);
    RootByteDataset rds0 = reader0.readRootDataset();
    if (rds0 == null) {
      log.info0('Unreadable File: $path');
      return false;
    }
    if (rds0.parseInfo == null) {
      log.info0('Bad File - No ParseInfo: $path');
      return false;
    }
    var bytes0 = reader0.buffer;
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS String: ${rds0.transferSyntaxString}
$pad    TS: ${rds0.transferSyntax}''');
    if (rds0.parseInfo != null)
      log.debug('$pad    ${rds0.parseInfo.info}');

// TODO: move into dataset.warnings.
    ByteElement e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      log.debug1('$pad  e: ${e.info}');
    }

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');


    if (rds0 != null) log.info0('$pad Success!');
    return true;
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $path');
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
    return false;
  }
  return false;
}