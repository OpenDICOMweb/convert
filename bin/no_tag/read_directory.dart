// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:common/timestamp.dart';
import 'package:path/path.dart' as p;

import 'read_file_list.dart';

String inRoot0 = "C:/odw/test_data/sfd/CR";
String inRoot1 = "C:/odw/test_data/sfd/CR_and_RF";
String inRoot2 = "C:/odw/test_data/sfd/CT";
String inRoot3 = "C:/odw/test_data/sfd/MG";
String inRoot4 = "C:/odw/test_data/sfd";
String inRoot5 = "C:/odw/test_data";
String mWeb = "C:/odw/test_data/mweb";
String testData = "C:/odw/test_data";

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 =  'test/output/root4';

String mweb0 = 'C:/odw/test_data/mweb/10 Patient IDs';
String mweb1 = 'C:/odw/test_data/mweb/100 MB Studies';
String hologic = 'C:/odw/test_data/mweb/Hologic';

String badDir0 = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";
String badDir1 = "C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop";

Logger log = new Logger("read_a_directory", watermark: Severity.info);

void main() {
  int fsEntityCount;

  Directory dir = new Directory(inRoot3);

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  List<String> files = <String>[];
  for (FileSystemEntity fse in fList) {
    if (fse is File) {
      var path = fse.path;
      var ext = p.extension(path);
      if (ext == '.dcm') {
        log.debug('File: $fse');
        files.add(fse.path);
      }
    }
  }

  var timer = new Stopwatch();
  log.info('Reading ${files.length} files from ${dir.path}:');
  var timestamp = new Timestamp('Starting Read ...');
  timer.start();
  log.info('   at: $timestamp');
  var reader = new FileListReader(files, fmiOnly: true, printEvery: 100);
  reader.read;
  timer.stop();
  log.info('Elapsed time: ${timer.elapsed}');
}
