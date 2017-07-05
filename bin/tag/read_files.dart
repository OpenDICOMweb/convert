// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/utilities/file_list_reader.dart';



final Logger log =
    new Logger("io/bin/read_files.dart", watermark: Severity.debug);

void main() {
 // readFile(path0);

  readFiles(badFileList4);
}

void readFile(String path) {
  File input = new File(path);
  RootByteDataset rds = ByteReader.readFile(input) as RootByteDataset;
  if (rds == null) {
    log.error('Null Instance $path');
    return null;
  }
  log.info('readFile: ${rds.info}');
  // if (log.watermark == Severity.debug) formatDataset(rds);
}

void formatDataset(RootByteDataset rds, [bool includePrivate = true]) {
  var z = new Formatter(maxDepth: 146);
  log.debug(rds.format(z));
//  for (PrivateGroup pg in rds.privateGroups)
//    log.debug(pg.info);
}

void readFiles(List<String> paths) {
  log.info('Reading $paths Files:');
  var reader = new FileListReader(paths);
  reader.read;
}

/* Flush if not needed
RootByteDataset _readFile(File file) {
  Uint8List bytes = file.readAsBytesSync();
  if (bytes.length < 8 * 1024)
    log.warn('***** Short file length: ${bytes.length} - ${file.path}');
  log.debug('Reading file: $file, length: ${bytes.length}');
  RootByteDataset rds;
  try {
    rds = ByteReader.readBytes(bytes, path: file.path);
  } on InvalidTransferSyntaxError catch(e) {
    log.debug(e);
    return null;
  } catch(e) {
    log.info('Failed read Dataset, now trying FMI');
    rds = ByteReader.readBytes(bytes, path: file.path, fmiOnly: true);
  }
  return rds;
}*/
