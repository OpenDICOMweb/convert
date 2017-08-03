// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:io';

import 'package:common/common.dart';

import 'package:dcm_convert/src/dcm/io_utils.dart';
import 'job_reporter.dart';

class JobRunner {
  Directory directory;
  List files;
  bool Function(File f) doFile;
  JobReporter reporter;
  //TODO: figure out the best way to handle this.
  bool throwOnError;

  JobRunner(this.directory, this.doFile,
      {int interval, Logger logger, this.throwOnError = true})
      : reporter = new JobReporter(fileCount(directory),
      from: directory.path, short: interval);

  JobRunner.list(this.files, this.doFile,
      {int interval, Logger logger, this.throwOnError = true})
      : reporter =
  new JobReporter(files.length, from: 'FileList', short: interval);

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

  String runFile(File f, [int indent]) =>
      reporter.report(doFile(f), cleanPath(f.path));

  static void job(Directory dir, bool Function(File f) doFile,
      {int interval, Level level = Level.info, bool throwOnError = true}) {
    var program = Platform.script.toFilePath();
    final Logger log = new Logger(program, level);
    var job = new JobRunner(dir, doFile, interval: interval, logger: log);
    stdout.writeln('Running: $program');
    job.run();
  }

  static void fileList(List<String> files, bool Function(File f) doFile,
      {int interval, Level level = Level.debug, bool throwOnError = true}) {
    var program = Platform.script.toFilePath();
    final Logger log = new Logger(program, level);
    var job =
    new JobRunner.list(files, doFile, interval: interval, logger: log);
    stdout.writeln('Running: $program');
    job.runList();
  }
}