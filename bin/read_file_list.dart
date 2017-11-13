// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:io/io.dart';
import 'package:dcm_convert/tools.dart';
import 'package:system/server.dart';

import 'package:dcm_convert/data/bad_files_0.dart';
import 'package:dcm_convert/data/bad_files_1.dart';
import 'package:dcm_convert/data/test_files.dart';

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

//TODO: modify so that it takes the following arguments
// 1. dirname
// 2. reportIncrement
void main() {
  /// The processed arguments for this program.
  JobArgs jobArgs;

  Server.initialize(name: 'read_file_list.dart', level: Level.debug);

  print(jobArgs.info);

//  if (jobArgs.showHelp) showHelp();

//  system.log.level = jobArgs.baseLevel;

  final reader = new FileMapReader()

  JobRunner.fileList(tes, doReadByteFile, level: Level.info);
}
