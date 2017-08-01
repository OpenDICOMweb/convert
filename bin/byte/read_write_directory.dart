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

import 'timing_harness.dart';

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
  final Logger log = new Logger("read_a_directory", watermark: Severity.error);
  DcmReader.log.watermark = Severity.error;
  DcmWriter.log.watermark = Severity.error;
  FileListReader.log.watermark = Severity.error;

  //TODO: modify so that it reads one directory at a time and recursively
  // walks the tree.
  //TODO: add asyn argument and async I/O to handle multiple files at the same
  // time.
  /// *** Change directory path name here

  String path = sfdMG;
  Directory dir = new Directory(path);

  //TODO: replaced with directory utilities sync, and async
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

  TimingHarness harness =
      new TimingHarness(files.length, doPrint: true, interval: 10, from: path);

  harness.startReport;
  for (int i = 0; i < files.length; i++) {
    var good =
        byteReadWriteFileChecked(files[i], i, harness.widthOfTotal, true, true);
    harness.report(good, files[i]);
  }

  harness.endReport;
}
