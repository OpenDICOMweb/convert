// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/server.dart';

import 'job_reporter.dart';

class JobRunner {
  Directory directory;
  List files;
  bool Function(File f) doFile;
  JobReporter reporter;
  List<String> failures = <String>[];
  //TODO: figure out the best way to handle this.
  bool throwOnError;

  JobRunner(this.directory, this.doFile,
      {int interval = 100, Level level = Level.info0, this.throwOnError = true})
      : reporter =
            new JobReporter(fileCount(directory), from: directory.path, short: interval) {
    system.log.level = level;
    _greeting();
  }

  JobRunner.list(this.files, this.doFile,
      {int interval = 100, level =  Level.info0, this.throwOnError = true})
      : reporter = new JobReporter(files.length, from: 'FileList', short: interval) {
    system.log.level = level;
    _greeting();
  }

  Future<Null> run() async {
    reporter.startReport;
    await walkDirectory(directory, runFile);
    reporter.endReport;
  }

  Future<Null> runList() async {
    reporter.startReport;
    await walkPathList(files, runFile);
    reporter.endReport;
  }

  String runFile(File f, [int indent]) {
    var path = cleanPath(f.path);
    bool success;
    try {
      success = doFile(f);
      if (!success) failures.add(path);
    } catch (e) {
      print(e);
      print('In File: $path');
      if (throwOnError) rethrow;
    }
    return reporter.report(success, path);
  }

  static void _greeting() =>
    stdout.writeln('Job Runner:');

  static void job(Directory dir, bool Function(File f) doFile,
      {int interval, Level level = Level.info, bool throwOnError = true}) {
    var job = new JobRunner(dir, doFile, interval: interval);
    job.run();
  }

  static void fileList(List<String> files, bool Function(File f) doFile,
      {int interval, Level level = Level.debug, bool throwOnError = true}) {
    var job = new JobRunner.list(files, doFile, interval: interval);
    job.runList();
  }
}
