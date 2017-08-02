// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:io';

import 'package:common/common.dart';

import 'package:dcm_convert/src/dcm/io_utils.dart';

/// A class used to monitor the status of a job.
class JobReporter {
  final int total;
  final String from;
  final int interval;
  final Timer timer;
  final bool doPrint;
  final Logger logger;
  final bool logIt;
  final bool doReportFailure;

  Logger _log;
  DateTime _startTime;
  DateTime _endTime;
  Duration _totalElapsed;

  // The number of objects processed
  int _count = 0;
  int _success = 0;
  int _failure = 0;

  JobReporter(this.total,
      {this.from,
      this.interval = 100,
      this.doPrint = true,
      this.logger,
      this.doReportFailure = true})
      : logIt = (logger != null),
        timer = new Timer(start: false);

  String operator +(int v) {
    _count++;
    return (_count % interval == 0) ? report : "";
  }

  Level get Level => _log.level;

  void set Level(Level s) => _log.level = s;

  String get _from => (from == null) ? "" : "from $from";

  DateTime get startTime => _startTime;

  DateTime get endTime => _endTime;

  int get count => _count;

  int get countWidth => '$total'.length;

  int get success => _success;

  int get failure => _failure;

  bool get check => (_count % interval == 0) ? true : false;

  /// Starts the clock and returns a useful message
  String get startReport {
    _startTime = new DateTime.now();
    timer.start();
    return maybePrint(_startMsg);
  }

  /// Returns an end of job report
  String get endReport {
    timer.stop();
    _endTime = new DateTime.now();
    _totalElapsed = _endTime.difference(_startTime);
    return maybePrint(_endMsg);
  }

  String report(bool wasSuccessful, String name, [bool force = false]) {
    _count++;
    if (wasSuccessful) {
      _success++;
      if (force || check) {
        var n = '$_count'.padLeft(countWidth);
        var msg = '$n: ${timer.split} $name';
        return maybePrint(msg);
      }
    } else if (!wasSuccessful && doReportFailure) {
      _failure++;
      var n = '$_count'.padLeft(countWidth);
      var msg = '$n: ${timer.split} ** Failure $name';
      return maybePrint(msg);
    }
    return "";
  }

  String maybePrint(String msg) {
    if (doPrint) stdout.writeln(msg);
    if (logIt) logger.info(msg);
    return msg;
  }

  String get _startMsg => '''Reading $total files $_from
Started at $startTime\n''';

  String get _endMsg => '''\n\nEnded at $_endTime
Total Elapsed: $_totalElapsed (wall clock)
Timer.elapsed: ${timer.elapsed}');
Success $_success, 
Failure $_failure, 
Total ${_success+_failure}''';
}

const dcmExtensions = const <String>["dcm", ""];

class JobRunner {
  Directory directory;
  bool Function(File f) doFile;
  JobReporter reporter;

  JobRunner(this.directory, this.doFile, {int interval = 10, Logger logger})
      : reporter = new JobReporter(fileCount(directory),
            from: directory.path, interval: interval);

  Future<Null> run() async {
    reporter.startReport;
    await walkDirectory(
        directory,
        (File f, [int indent]) =>
            reporter.report(doFile(f), cleanPath(f.path)));
    reporter.endReport;
  }

  static void job(Directory dir, bool Function(File f) doFile,
      {int interval = 10, Level level = Level.info}) {
    var program = Platform.script.toFilePath();
    final Logger log = new Logger(program, level);
    var job = new JobRunner(dir, doFile, interval: interval, logger: log);
    stdout.writeln('Running: $program');
    job.run();
  }
}
