// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:timing/timer.dart';
import 'package:system/system.dart';
/// A class used to monitor the status of a job.
class JobReporter {
  final int total;
  final String from;
  final int shortInterval;
  //Urgent: add long interval
  int longInterval;
  final Timer timer;
  final bool doPrint;
  final Logger log;
  final bool logIt;
  final bool doReportFailure;

  DateTime _startTime;
  DateTime _endTime;
  Duration _totalElapsed;

  // The number of objects processed
  int _count = 0;
  int _success = 0;
  int _failure = 0;

  JobReporter(this.total,
      {this.from,
      int short,
        int long,
      this.doPrint = true,
      this.logIt = true,
      this.doReportFailure = true})
      //Urgent: figure out how to calculate interval.
      : this.shortInterval = (short == null) ? total ~/ 50 : short,
        this.log = (logIt) ? new Logger('JobReporter') : null,
        this.timer = new Timer(start: false) {
    this.longInterval = (long == null) ?  50 * shortInterval : long;
  }

  String operator +(int v) {
    _count++;
    return (_count % shortInterval == 0) ? report : "";
  }

  Level get level => log.level;

  void set level(Level level) => log.level = level;

  String get _from => (from == null) ? "" : "from $from";

  DateTime get startTime => _startTime;

  DateTime get endTime => _endTime;

  int get count => _count;

  int get countWidth => '$total'.length;

  int get success => _success;

  int get failure => _failure;

  bool get check => (_count % shortInterval == 0) ? true : false;

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

  //TODO: need a better name for this
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
    if (logIt) {
      log.info0(msg);
    } else {
      if (doPrint) stdout.writeln(msg);
    }
    return msg;
  }

  String get _startMsg => '''Reading $total files '$_from'
Started at $startTime\n''';

  String get _endMsg => '''\n\nEnded at $_endTime
Total Elapsed: $_totalElapsed (wall clock)
Timer.elapsed: ${timer.elapsed}');
Success $_success, 
Failure $_failure, 
Total ${_success+_failure}''';
}

const dcmExtensions = const <String>["dcm", ""];


