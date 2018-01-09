// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:system/core.dart';
import 'package:timer/timer.dart';

int getShortInterval(int total) {
  if (total < 20) return 1;
  if (total < 100) return 5;
  if (total < 1000) return 50;
  if (total < 10000) return 500;
  return 1000;
}

// Enhancement: add the ability to report every n seconds instead of n files
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
  final bool showPath;
  final List<String> failuresList = <String>[];

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
      this.logIt = false,
      this.doReportFailure = true,
      this.showPath = false})
      //Urgent: figure out how to calculate interval.
      : this.shortInterval = (short == null) ? getShortInterval(total) : short,
        this.log = (logIt) ? new Logger('JobReporter') : null,
        this.timer = new Timer(start: false) {
    longInterval = (long == null) ? 10 * shortInterval : long;
    print('short: $short');
    print('shortInterval: $shortInterval');
    print('long: $long');
    print('longInterval: $longInterval');
  }

  String operator +(int v) {
    _count++;
    return (_count % shortInterval == 0) ? report : '';
  }

  Level get level => log.level;

  set level(Level level) => log.level = level;

  String get _from => (from == null) ? '' : 'from $from';

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
  String report(String path, {bool wasSuccessful, bool force = false}) {
    _count++;
    if (wasSuccessful) {
      _success++;
      if (force || check) maybePrint(shortMsg(path));
    } else if (!wasSuccessful && doReportFailure) {
      _failure++;
      failuresList.add(path);
      final n = '$_count'.padLeft(countWidth);
      final msg = '$n: ** Failure $path';
      return maybePrint(msg);
    }
    return '';
  }

  String shortMsg(String path) {
    final n = '$_count'.padLeft(countWidth);
    final p = (showPath) ? path : '';
    var elapsed = timer.elapsed.toString();
    final dotPos = elapsed.indexOf('.');
    elapsed = elapsed.substring(0, dotPos);
    return '$n: ${timer.split} $elapsed $p';
  }

  String maybePrint(String msg) {
    if (logIt) log.info0(msg);
    if (doPrint) stdout.writeln(msg);
    return msg;
  }

  String get failures {
    final sb  =  new StringBuffer('Failures($_failure):');
    for (var s in failuresList) sb.write('  $s\n');
    return sb.toString();
  }

  String get _startMsg => '''Reading $total files '$_from'
Started at $startTime''';

  int get usPerFile => timer.elapsed.inMicroseconds ~/ total;

  String get _endMsg => '''\n
           Start at: $startTime
           Ended at: $_endTime
   Total wall clock: $_totalElapsed
            Success: $_success
            Failure: $_failure
              Total: ${_success + _failure}
Timer total elapsed: ${timer.elapsed}
      Timer average: ${timer.average(total)}
  Microseconds/File: $usPerFile
       Files/Second: ${1000000 ~/ usPerFile}
$failures
''';
}

const List<String> dcmExtensions = const <String>['dcm', ''];
