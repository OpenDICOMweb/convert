// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/convert.dart';
import 'package:core/server.dart';
import 'package:path/path.dart' as p;

//import 'package:convert/data/test_directories.dart';

const String dir6684_2017_5 = 'C:/acr/odw/test_data/6684/2017/5';
const String dir0 = 'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/'
    'Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/';
const String outRoot0 = 'test/output/root0';
const String outRoot1 = 'test/output/root1';
const String outRoot2 = 'test/output/root2';
const String outRoot3 = 'test/output/root3';
const String outRoot4 = 'test/output/root4';

//TODO: modify so that it takes the following arguments
// 1. dirname
// 2. reportIncrement
void main() {
  Server.initialize(name: 'ReadFile', level: Level.debug2, throwOnError: true);
  var success = 0;
  var failure = 0;

  system.log.level = Level.error;

  //TODO: modify so that it reads one directory at a time and recursively
  // walks the tree.
  //TODO: add asyn argument and async I/O to handle multiple files at the same
  // time.
  /// *** Change directory path name here
  const reportEveryNFiles = 10;
  const path = dir6684_2017_5;
  final dir = new Directory(path);

  final fList = dir.listSync(recursive: true);
  final fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  final files = <String>[];
  for (var fse in fList) {
    if (fse is! File) continue;
    final path = fse.path;
    final ext = p.extension(path);
    if (ext == '.dcm' || ext == '') {
      log.debug('File: $fse');
      files.add(fse.path.replaceAll('\\', '/'));
    }
  }

  final program = Platform.script;
  final startTime = new DateTime.now();
  print('$program');
  print('Reading ${files.length} files from ${dir.path}:');
  print('Started at $startTime');

  final width = '${files.length}'.length;

  final timer = new Timer();
  for (var i = 0; i < files.length; i++) {
    if (i % reportEveryNFiles == 0) {
      final n = '$i'.padLeft(width);
      print('$n: ${timer.split} ${files[i]}');
    }
    if (byteReadWriteFileChecked(files[i],
        fileNumber: i, width: width, fast: true)) {
      success++;
    } else {
      failure++;
    }
  }
  timer.stop();

  final endTime = new DateTime.now();
  final totalElapsed = endTime.difference(startTime);
  print('Ended at $endTime');
  print('Total Elapsed: $totalElapsed (wall clock');
  print('Timer.elapsed: ${timer.elapsed}');
  print('Success $success, Failure $failure, Total ${success+failure}');
}
