// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io' show Platform;
import 'package:args/args.dart';
import 'package:core/core.dart';

class JobArgs {
  /// The name of the program that is running
  String program;

  /// The
  String logPath;

  /// The location of the summary file, which describes the results.
  String summary;

  /// The location to put error log files
  String outDir;

  /// Report every n files processed
  int shortMsgEvery;

  int longMsgEvery = 10000;

  /// The log Level for first run
  Level baseLevel;

  /// The Error Level for logging error run.
  //TODO: finish
  Level errorLevel;

  /// The parser's [ArgResults].
  ArgResults argResults;

  /// If true displays a help message and exits.
  bool showHelp = false;

  /// The argument processor for Job arguments.
  ArgParser parser;


  JobArgs(List<String> args) {
	  program = programName;
	  parser = getParser();
	  argResults = parser.parse(args);
  }

  void setLogPath(Object path) => (path is String) ? logPath = path : null;

  void setSummary(Object results) => (results is String) ? summary = results : null;

  void setOutDir(Object dir) => (dir is String) ? outDir = dir : null;

  void setShortInterval(Object count) =>
      (count is String) ? shortMsgEvery = parseInt(count) : null;

  void setLongInterval(Object count) =>
		  (count is String) ? longMsgEvery = parseInt(count) : null;

  void setDebugLevel(Object mode) => baseLevel = Level.lookup(mode);

  int get length => argResults.arguments.length;

  String get programName {
    final path = Platform.script.pathSegments;
    final end = path.last.lastIndexOf('.');
    final name = path.last.substring(0, end);
    return name;
  }

  String get help => parser.usage;

  String get info => '''JobArgs:
  program: $program
  logPath: '$logPath'
  summary: '$summary'
  outDir: '$outDir'
  every: $shortMsgEvery
  baseLevel: $baseLevel
  errorLevel: $errorLevel
  argResults: ${argResults.arguments}
  showHelp: $showHelp
  ''';

  int parseInt(String s) => int.parse(s, onError: (s) => 100);

  ArgParser getParser() => new ArgParser()
    ..addOption('logFile',
        abbr: 'f',
        defaultsTo: './$program.log',
        callback: setLogPath,
        help: 'The log file- defaults to ./logger.log')
    ..addOption('results',
        abbr: 'r',
        defaultsTo: './results.txt',
        callback: setSummary,
        help: 'The results file')
    ..addOption('outDir',
        abbr: 'o',
        defaultsTo: './output',
        callback: setOutDir,
        help: 'The output directory - created files have same name as source')
    //TODO: need better name
    ..addOption('every',
        abbr: 'e',
        defaultsTo: '1000',
        callback: setShortInterval,
        help: 'print a progress message every n files processed"')
    // These next options are for the logger Level
    ..addOption('Level',
        abbr: 'l',
        allowed: [
          'error', 'config', 'warn0', 'warn1', 'info0', 'info1',
          'debug0', 'debug1', 'debug2', 'debug3' //No Reformat
        ],
        defaultsTo: 'error',
        callback: setDebugLevel,
        help: 'The logging mode - defaults to info')
    ..addFlag('silent', abbr: 's', callback: (v) {
      if (v) baseLevel ??= Level.error;
    }, help: 'Silent mode - mode is set to "error"')
    ..addFlag('config', abbr: 'c', defaultsTo: false, callback: (v) {
      if (v) baseLevel ??= Level.config;
    }, help: 'mode is set to "config"')
    ..addFlag('warn', abbr: 'w', defaultsTo: false, callback: (v) {
      if (v) baseLevel ??= Level.warn1;
    }, help: 'mode is set to "info"')
    ..addFlag('info', abbr: 'i', defaultsTo: false, callback: (v) {
      if (v) baseLevel ??= Level.info1;
    }, help: 'mode is set to "info"')
    ..addFlag('debug', abbr: 'd', defaultsTo: false, callback: (v) {
      if (v) baseLevel ??= Level.debug0;
    }, help: 'mode is set to "debug"')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false, callback: (v) {
      if (v) baseLevel ??= Level.debug3;
    }, help: 'mode is set to "debug3"')
    // Usage option
    ..addFlag('help',
        abbr: 'h',
        defaultsTo: false,
        callback: (v) => (v) ? showHelp = true : showHelp = false,
        help: 'prints some helpful information about this program');

  static JobArgs parse(List<String> args) {
    final jArgs = new JobArgs(args);
    return jArgs;
  }

  @override
  String toString() => '$runtimeType: $argResults';
}
