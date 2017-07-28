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

import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';
import 'package:dcm_convert/src/dcm/byte_read_utils.dart';

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

void main() {
  final Logger log = new Logger("read_a_directory", watermark: Severity.info);
  int success = 0;
  int failure = 0;

  DcmReader.log.watermark = Severity.config;
  DcmWriter.log.watermark = Severity.config;
  FileListReader.log.watermark = Severity.config;

  /// *** Change directory path name here
  String path = dir6688;
  Directory dir = new Directory(path);

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  int fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  List<String> files = <String>[];
  for (FileSystemEntity fse in fList) {
    if (fse is! File) continue;
    var path = fse.path;
    var ext = p.extension(path);
    if (ext == '.dcm' || ext == "") {
      log.debug('File: $fse');
      files.add(fse.path.replaceAll('\\', '/'));
    }
  }

  var timer = new Timer();
  log.config('Reading ${files.length} files from ${dir.path}:');
  int width = '${files.length}'.length;

  for (int i = 0; i < files.length; i++) {
    if (byteReadWriteFileChecked(files[i], i, width)) {
      success++;
    } else {
      failure++;
    }
  }
  log.config('Success $success, Failure $failure, Total ${success+failure}');
  log.config('Elapsed time: ${timer.elapsed}');
}
