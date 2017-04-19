// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:common/timestamp.dart';
import 'package:convertX/convert.dart';
import 'package:core/core.dart';
import 'package:path/path.dart' as p;

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

  Directory dir = new Directory(testData);

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
  log.info('Reading ${files.length} files from ${dir.path}:');
  var timestamp = new Timestamp('Starting Read ...');
  timer.start();
  log.info('   at: $timestamp');
  readFileList(files);
  timer.stop();
  log.info('Elapsed time: ${timer.elapsed}');
}

void readFileList(List<File> files, {bool fmiOnly = false}) {
  int printEvery = 25;
  int fsEntityCount;
  int successCount;
  int failureCount;

  int filesCount = files.length;


  int count = -1;
  RootDataset rds;
  List<String> success = [];
  List<String> failure = [];
  for (File file in files) {
    if (count++ % printEvery == 0) log.info('$count good(${success.length}), '
        'bad(${failure.length})');
    log.debug('Reading file: $file');
    try {
      rds = readRDS(file);
      if (rds == null) {
        failure.add('"${file.path}"');
      } else {
        log.debug('Dataset: ${rds.info}');
        success.add('"${file.path}"');
      }
      // print('output:\n${instance.patient.format(new Prefixer())}');
    } catch (e) {
      log.info('Fail: ${file.path}');
      failure.add('"${file.path}"');
   //   log.info('failures: ${failure.length}');
      continue;
    }
    log.reset;
  }
  successCount = success.length;
  failureCount = failure.length;
  // log.info(instance.study.summary);
  // log.info('Active Patients: $activeStudies');
  log.info('FSEntities: $fsEntityCount');
  log.info('Files: $filesCount');
  log.info('Success: $successCount');
  log.info('Failure: $failureCount');
  log.info('Total: ${successCount + failureCount}');
//  var good = success.join(',  \n');
  var bad = failure.join(',  \n');
//  log.info('Good Files: [\n$good,\n]\n');
  log.info('bad Files: [\n$bad,\n]\n');
}

RootDataset readRDS(File f) {
  var bytes = f.readAsBytesSync();
  // print('LengthInBytes: ${bytes.length}');
  DcmDecoder decoder = new DcmDecoder.fromSource(new DSSource(bytes, f.path));
  return decoder.readRDS();
}
