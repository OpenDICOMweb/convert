// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/core.dart';

//import 'package:convert/data/test_files.dart';
import 'package:convert/convert.dart';
import 'package:convert/src/utilities/file_list_reader.dart';

const String dir6684_2017_5 = 'C:/acr/odw/test_data/6684/2017/5';

void main() {
  // readFile(path0);

  const dir = dir6684_2017_5;
  final files = fileListFromDirectory(dir);
  readFiles(files);
}

void readFile(String path) {
  final input = new File(path);
  final rds = TagReader.readFile(input);
  if (rds == null) {
    log.error('Null Instance $path');
    return null;
  }
  log.info0('readFile: ${rds.info}');
  // if (log.level == Level.debug) formatDataset(rds);
}

void formatDataset(BDRootDataset rds, {bool includePrivate = true}) {
  final z = new Formatter(maxDepth: 146);
  log.debug(rds.format(z));
  for (var pg in rds.privateGroups) log.debug(pg.info);
}

void readFiles(List<String> paths) {
  log.info0('Reading $paths Files:');
  new FileListReader(paths)..read;
}
