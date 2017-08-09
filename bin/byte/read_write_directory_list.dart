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

var dir0 =
    'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/';
String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

//TODO: modify so that it takes the following arguments
// 1. dirname
// 2. reportIncrement
void main() {
  final Logger log = new Logger("read_a_directory");
  int success = 0;
  int failure = 0;

  DcmReader.log.level = Level.error;
  DcmWriter.log.level = Level.error;

  FileListReader.log.level = Level.error;

  //TODO: modify so that it reads one directory at a time and recursively
  // walks the tree.
  //TODO: add asyn argument and async I/O to handle multiple files at the same
  // time.
  /// *** Change directory path name here
  int reportEveryNFiles = 100;
  String path = sfdMG;
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

  Uri program = Platform.script;
  DateTime startTime = new DateTime.now();
  print('$program');
  print('Reading ${files.length} files from ${dir.path}:');
  print('Started at $startTime');

  int width = '${files.length}'.length;

  var timer = new Timer();
  for (int i = 0; i < files.length; i++) {
    if (i % reportEveryNFiles == 0) {
      var n = '$i'.padLeft(width);
      print('$n: ${timer.split} ${files[i]}');
    }
    if (byteReadWriteFileChecked(files[i], i, width, true, true)) {
      success++;
    } else {
      failure++;
    }
  }
  timer.stop();

  DateTime endTime = new DateTime.now();
  Duration totalElapsed = endTime.difference(startTime);
  print('Ended at $endTime');
  print('Total Elapsed: $totalElapsed (wall clock');
  print('Timer.elapsed: ${timer.elapsed}');
  print('Success $success, Failure $failure, Total ${success+failure}');

}
