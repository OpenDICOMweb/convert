// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:io';

import 'package:core/core.dart';

import 'package:convert/src/tools/job/job_args.dart';
import 'package:convert/src/tools/job/job_reporter.dart';
import 'package:convert/src/utilities/io_utils.dart';

// ignore_for_file: avoid_catches_without_on_clauses

// **** change this name when testing
const String defaultDirName = 'C:/acr/odw/test_data/6684/2017/5/12/16/0EE11F7A';

/// Get target directory and validate it.
Directory getDirectory(JobArgs args) {
  String dirName;
  if (args.length == 0) {
    stderr
        .write('No Directory name supplied - defaulting to $defaultDirName\n');
    dirName = defaultDirName;
  } else {
    dirName = args.argResults.arguments[0];
  }

  final dir = pathToDirectory(dirName);
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

typedef Future<bool> DoFile(File f, {bool throwOnError, bool fast});

class JobRunner {
  static const int defaultInterval = 10;
  Directory directory;
  Iterable files;
  DoFile doFile;
  JobReporter reporter;
  List<String> failures = <String>[];
  bool throwOnError;
  bool fast;

  factory JobRunner(JobArgs jobArgs, DoFile doFile,
      {int interval = defaultInterval,
      Level level = Level.info0,
      bool throwOnError = true}) {
    final dir = getDirectory(jobArgs);
    final reporter = getJobReporter(fileCount(dir), dir.path, interval);
    return new JobRunner._(dir, null, doFile, reporter,
        level: level, throwOnError: throwOnError);
  }

  factory JobRunner.list(Iterable<File> files, DoFile doFile,
      {int interval = defaultInterval,
      Level level = Level.info0,
      bool throwOnError = true}) {
    final reporter = getJobReporter(files.length, 'FileList', interval);
    return new JobRunner._(null, files, doFile, reporter,
        level: level, throwOnError: throwOnError);
  }

  JobRunner._(this.directory, this.files, this.doFile, this.reporter,
      {Level level = Level.info0, this.throwOnError = true, this.fast = true}) {
    system.log.level = level;
    _greeting();
  }

  Future<String> run() async {
    reporter.startReport;
    await walkDirectoryFiles(directory, runFile);
    return reporter.endReport;
  }

  Future<String> runList() async {
    reporter.startReport;
    await walkPathList(files, runFile);
    return reporter.endReport;
  }

  Future<Null> runFile(File f, [int indent]) async {
    final path = cleanPath(f.path);
    bool success;
    try {
      success = await doFile(f, throwOnError: throwOnError, fast: fast);
      if (!success) failures.add(path);
    } catch (e) {
      print('Caught: $e\n  on File: $f');
      if (throwOnError) rethrow;
    }
    reporter.report(path, wasSuccessful: success);
  }

  static void _greeting() => stdout.writeln('Job Runner:');

  static void job(JobArgs jobArgs, DoFile doFile,
          {int interval, Level level = Level.info, bool throwOnError = true}) =>
      new JobRunner(jobArgs, doFile,
          interval: interval, throwOnError: throwOnError)
        ..run();

  static void fileList(Iterable<File> files, DoFile doFile,
          {int interval,
          Level level = Level.debug,
          bool throwOnError = true}) =>
      new JobRunner.list(files, doFile, interval: interval)..runList();

  static void pathList(List<String> paths, DoFile doFile,
      {int interval = defaultInterval,
      Level level = Level.info0,
      bool throwOnError = true}) {
    final files = paths.map((p) => new File(p));
    fileList(files, doFile,
        interval: interval, level: level, throwOnError: throwOnError);
  }
}
