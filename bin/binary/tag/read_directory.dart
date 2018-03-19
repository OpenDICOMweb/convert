// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/server.dart';
import 'package:path/path.dart' as p;
import 'package:convert/convert.dart';

// ignore_for_file: avoid_catches_without_on_clauses

String inRoot0 = 'C:/acr/odw/test_data/sfd/CR';
String inRoot1 = 'C:/acr/odw/test_data/sfd/CR_and_RF';
String inRoot2 = 'C:/acr/odw/test_data/sfd/CT';
String inRoot3 = 'C:/acr/odw/test_data/sfd/MG';
String inRoot4 = 'C:/acr/odw/test_data/sfd';
String inRoot5 = 'C:/acr/odw/test_data';
String mWeb = 'C:/acr/odw/test_data/mweb';
String testData = 'C:/acr/odw/test_data';

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

String mweb0 = 'C:/acr/odw/test_data/mweb/10 Patient IDs';
String mweb1 = 'C:/acr/odw/test_data/mweb/100 MB Studies';
String hologic = 'C:/acr/odw/test_data/mweb/Hologic';

String badDir0 = 'C:/acr/odw/test_data/mweb/100 MB Studies/MRStudy';
String badDir1 = 'C:/acr/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop';
const String dir6684_2017_5 = 'C:/acr/odw/test_data/6684/2017/5';

void main() {
  Server.initialize(name: 'Tag Read Directory', level: Level.info, throwOnError: true);
  int fsEntityCount;

  final dir = new Directory(dir6684_2017_5);

  final fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  final files = <File>[];
  for (var fse in fList) {
    if (fse is File) {
      final path = fse.path;
      final ext = p.extension(path);
      if (ext == '.dcm' || ext == '') {
        log.debug('File: $fse');
        files.add(fse);
      }
    }
  }

  final timer = new Stopwatch();
  log.info0('Reading ${files.length} files from ${dir.path}:');
  final timestamp = new Timestamp('Starting Read ...');
  timer.start();
  log.info0('   at: $timestamp');
  readFileList(files);
  timer.stop();
  log.info0('Elapsed time: ${timer.elapsed}');
}

void readFileList(List<File> files, {bool fmiOnly = false}) {
  const printEvery = 5;
  int fsEntityCount;
  int successCount;
  int failureCount;

  final filesCount = files.length;

  var count = -1;
  TagRootDataset rds;
  final success = <String>[];
  final failure = <String>[];
  for (var file in files) {
    if (count++ % printEvery == 0)
      log
        ..info0('$count good(${success.length}), bad(${failure.length})')
        ..debug('Reading file: $file');
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
  final bad = failure.join(',  \n');
  log
    ..info0('FSEntities: $fsEntityCount')
    ..info0('Files: $filesCount')
    ..info0('Success: $successCount')
    ..info0('Failure: $failureCount')
    ..info0('Total: ${successCount + failureCount}')
    ..info0('bad Files: [\n$bad,\n]\n');
}
