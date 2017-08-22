// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/logger.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:path/path.dart' as p;
import 'package:timing/timestamp.dart';

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

Logger log = new Logger("read_a_directory", Level.info);

void main() {
  int fsEntityCount;

  Directory dir = new Directory(mweb0);

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  List<File> files = <File>[];
  for (FileSystemEntity fse in fList) {
    if (fse is File) {
      var path = fse.path;
      var ext = p.extension(path);
      if (ext == '.dcm') {
        log.debug('File: $fse');
        files.add(fse);
      }
    }
  }

  var timer = new Stopwatch();
  log.info0('Reading ${files.length} files from ${dir.path}:');
  var timestamp = new Timestamp('Starting Read ...');
  timer.start();
  log.info0('   at: $timestamp');
  readFileList(files);
  timer.stop();
  log.info0('Elapsed time: ${timer.elapsed}');
}

void readFileList(List<File> files, {bool fmiOnly = false}) {
  int printEvery = 25;
  int fsEntityCount;
  int successCount;
  int failureCount;

  int filesCount = files.length;


  int count = -1;
  RootTagDataset rds;
  List<String> success = [];
  List<String> failure = [];
  for (File file in files) {
    if (count++ % printEvery == 0) log.info0('$count good(${success.length}), '
        'bad(${failure.length})');
    log.debug('Reading file: $file');
    try {
      rds = TagReader.readFile(file);
      if (rds == null) {
        failure.add('"${file.path}"');
      } else {
        log.debug('Dataset: ${rds.info}');
        success.add('"${file.path}"');
      }
      // print('output:\n${instance.patient.format(new Prefixer())}');
    } catch (e) {
      log.info0('Fail: ${file.path}');
      failure.add('"${file.path}"');
   //   log.info0('failures: ${failure.length}');
      continue;
    }
    log.reset;
  }
  successCount = success.length;
  failureCount = failure.length;
  // log.info0(instance.study.summary);
  // log.info0('Active Patients: $activeStudies');
  log.info0('FSEntities: $fsEntityCount');
  log.info0('Files: $filesCount');
  log.info0('Success: $successCount');
  log.info0('Failure: $failureCount');
  log.info0('Total: ${successCount + failureCount}');
//  var good = success.join(',  \n');
  var bad = failure.join(',  \n');
//  log.info0('Good Files: [\n$good,\n]\n');
  log.info0('bad Files: [\n$bad,\n]\n');
}
