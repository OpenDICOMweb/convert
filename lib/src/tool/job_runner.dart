// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:io';

import 'package:dcm_convert/dcm.dart';
import 'package:system/system.dart';

import 'job_args.dart';
import 'job_reporter.dart';

// **** change this name when testing
const defaultDirName = 'C:/odw/test_data/mweb/100 MB Studies';

/// Get target directory and validate it.
Directory getDirectory(JobArgs args) {
  var dirName;
  if (args.length == 0) {
    stderr.write('No Directory name supplied - defaulting to $defaultDirName\n');
    dirName = defaultDirName;
  } else {
    dirName = args.argResults.arguments[0];
  }

  var dir = toDirectory(dirName);
  if (dir == null) {
    if (dirName[0] == '-') {
      stderr.write('Error: Missing directory argument - "$dir"');
    } else {
      stderr.write('Error: $dirName does not exist');
    }
    exit(-1);
  }
  return dir;
}

JobReporter getJobReporter(int fileCount, String path, int interval) =>
    new JobReporter(fileCount, from: path, short: interval);

class JobRunner {
  static const defaultInterval = 250;
  Directory directory;
  List files;
  bool Function(File) doFile;
  JobReporter reporter;
  List<String> failures = <String>[];
  //TODO: figure out the best way to handle this.
  bool throwOnError;

  factory JobRunner(JobArgs jobArgs, bool Function(File) doFile,
      {int interval = defaultInterval,
      Level level = Level.info0,
      bool throwOnError = true}) {
    var dir = getDirectory(jobArgs);
    var reporter = getJobReporter(fileCount(dir), dir.path, interval);
    return new JobRunner._(dir, null, doFile, reporter,
       level: level, throwOnError: throwOnError);
  }

  factory JobRunner.list(List<File> files, bool Function(File) doFile,
      {int interval = defaultInterval, level = Level.info0, bool throwOnError = true}) {
    var reporter = getJobReporter(files.length, 'FileList', interval);
    return new JobRunner._(null, files, doFile, reporter,
        level: level, throwOnError: throwOnError);
  }

  JobRunner._(this.directory, this.files, this.doFile, this.reporter,
      {Level level = Level.info0,
      this.throwOnError = true}) {
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

  static void _greeting() => stdout.writeln('Job Runner:');

  static void job(JobArgs jobArgs, bool Function(File f) doFile,
      {int interval, Level level = Level.info, bool throwOnError = true}) {
    var job = new JobRunner(jobArgs, doFile, interval: interval);
    job.run();
  }

  static void fileList(List<File> files, bool Function(File f) doFile,
      {int interval, Level level = Level.debug, bool throwOnError = true}) {
    var job = new JobRunner.list(files, doFile, interval: interval);
    job.runList();
  }
}
