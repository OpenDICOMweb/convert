// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_directories.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:path/path.dart' as p;

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

void main() {
  final Logger log = new Logger("read_a_directory", Level.error);
  int fsEntityCount;

  log.level = Level.error;
  DcmWriter.log.level = Level.error;
  FileListReader.log.level = Level.error;

  /// *** Change directory path name here
  String path = dir6688;
  Directory dir = new Directory(path);

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;
  print('List: $fsEntityCount');
  log.debug('FSEntity count: $fsEntityCount');

  List<String> files = <String>[];
  for (FileSystemEntity fse in fList) {
    if (fse is! File) continue;
      var path = fse.path;
      var ext = p.extension(path);
      if (ext == '.dcm' || ext == "") {
        log.debug('File: $fse');
        files.add(fse.path);
      }
  }

  var timer = new Timer();
  log.config('Reading ${files.length} files from ${dir.path}:');
  var reader = new FileListReader(files, fmiOnly: true, printEvery: 100);
  reader.read;
  log.config('Elapsed time: ${timer.elapsed}');
}