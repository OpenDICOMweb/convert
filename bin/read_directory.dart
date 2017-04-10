// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:convertX/convert.dart';
import 'package:core/core.dart';
import 'package:path/path.dart' as p;

String inRoot0 = "C:/odw/test_data/sfd/CR";
String inRoot1 = "C:/odw/test_data/sfd/CR_and_RF";
String inRoot2 = "C:/odw/test_data/sfd/CT";
String inRoot3 = "C:/odw/test_data/sfd/MG";
String inRoot4 = "C:/odw/test_data/sfd";
String inRoot5 = "C:/odw/test_data";
String inRoot6 = "C:/odw/test_data/mweb";

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

String mweb0 = 'C:/odw/test_data/mweb/10 Patient IDs';
String mweb1 = 'C:/odw/test_data/mweb/100 MB Studies';
String hologic = 'C:/odw/test_data/mweb/Hologic';

String badDir = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";

void main() {
  int printEvery = 25;
  int fsEntityCount;
  int filesCount;
  int successCount;
  int failureCount;
  Logger log = new Logger("read_a_directory", watermark: Severity.info);

  Directory dir = new Directory(inRoot6);

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
  filesCount = files.length;
  log.info('Reading $filesCount files from ${dir.path}:');

  int count = -1;
  Instance instance;
  List<String> success = [];
  List<String> failure = [];
  for (File file in files) {
    if (count++ % printEvery == 0) log.info('$count good(${success.length}), '
        'bad(${failure.length})');
    log.debug('Reading file: $file');
    try {
      instance = readInstance(file);
      if (instance == null) {
        failure.add('"${file.path}"');
      } else {
        log.debug('instance: ${instance.info}');
        success.add('"${file.path}"');
      }
      // print('output:\n${instance.patient.format(new Prefixer())}');
    } catch (e) {
      log.info('Fail: ${file.path}');
      failure.add('"${file.path}"');
   //   log.info('failures: ${failure.length}');
      continue;
    }
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
  var good = success.join(',  \n');
  var bad = failure.join(',  \n');
  //log.info('Good Files: [\n$good,\n]\n');
  log.info('bad Files: [\n$bad,\n]\n');
}

Instance readInstance(File f) {
  var bytes = f.readAsBytesSync();
  // print('LengthInBytes: ${bytes.length}');
  DcmDecoder decoder = new DcmDecoder(new DSSource(bytes, f.path));
  return decoder.readInstance();
}
