// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/common.dart';

class TimingHarness {
  final int total;
  final String from;
  final int interval;
  final int widthOfTotal;
  final Timer timer;
  final bool doPrint;
  final Logger logger;
  final bool logIt;
  final bool doReportFailure;
  DateTime _startTime;
  DateTime _endTime;
  int _count = 0;
  int _success = 0;
  int _failure = 0;

  TimingHarness(this.total,
      {this.from,
      this.interval = 100,
      this.doPrint = true,
      this.logger,
      this.doReportFailure = true})
      : widthOfTotal = '$total'.length,
        logIt = (logger != null),
        timer = new Timer(start: false);

  String operator +(int v) {
    _count++;
    return (_count % interval == 0) ? report : "";
  }

  Uri get program => Platform.script;

  String get _from => (from == null) ? "" : "from $from";

  DateTime get startTime => _startTime;

  DateTime get endTime => _endTime;

  int get count => _count;

  int get success => _success;

  int get failure => _failure;

  bool get check => (_count % interval == 0) ? true : false;

  /// Starts the clock and returns a useful message
  String get startReport {
    _startTime = new DateTime.now();
    var msg = '''$program
Reading $total files $_from
Started at $startTime''';
    timer.start();
    return maybePrint(msg);
  }

  String report(bool wasSuccessful, String name, [bool force = false]) {
    _count++;
    if (wasSuccessful) {
      _success++;
    } else {
      _failure++;
    }
    if  (!wasSuccessful && doReportFailure)  {
      var n = '$_count'.padLeft(widthOfTotal);
      var msg = '$n: ${timer.split} ** Failure $name';
      return maybePrint(msg);
    } else if (force || check) {
      var n = '$_count'.padLeft(widthOfTotal);
      var msg = '$n: ${timer.split} $name';
      return maybePrint(msg);
    }
    return "";
  }

  String get endReport {
    timer.stop();
    _endTime = new DateTime.now();
    Duration totalElapsed = _endTime.difference(_startTime);
    var msg = '''Ended at $_endTime
Total Elapsed: $totalElapsed (wall clock)
Timer.elapsed: ${timer.elapsed}');
Success $_success, 
Failure $_failure, 
Total ${_success+_failure}''';
    return maybePrint(msg);
  }

  String maybePrint(String msg) {
    if (doPrint) print(msg);
    if (logIt) logger.info(msg);
    return msg;
  }
}
