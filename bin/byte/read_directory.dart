// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/byte_convert.dart.old';
import 'package:path/path.dart' as p;
import 'package:timer/timer.dart';
import 'package:system/server.dart';

//import 'package:dcm_convert/data/test_directories.dart';

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

void main() {
  Server.initialize(name: 'read_write_file', level: Level.error);

  /// *** Change directory path name here
  final path = 'C:/odw/test_data/sfd/MR/Patient_20_-_FMRI_brain/1_DICOM_Original';
  final dir = new Directory(path);
  final fList = dir.listSync(recursive: true);
  final fsEntityCount = fList.length;
  print('List: $fsEntityCount');
  log.debug('FSEntity count: $fsEntityCount');

  final files = <String>[];
  for (var fse in fList) {
    if (fse is! File) continue;
    final path = fse.path;
    final ext = p.extension(path);
    if (ext == '.dcm' || ext == '') {
      log.debug('File: $fse');
      files.add(fse.path);
    }
  }

  final timer = new Timer();
  log.config('Reading ${files.length} files from ${dir.path}:');
  new FileListReader(files, fmiOnly: true, printEvery: 100)..read;
  log.config('Elapsed time: ${timer.elapsed}');
}
