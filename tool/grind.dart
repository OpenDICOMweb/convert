// Copyright (c) 2016, 2017, 2018,
// Poplar Hill Informatics and the American College of Radiology
// All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the odw/LICENSE file.
// Primary Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.


import 'dart:async';
import 'dart:io';

import 'package:grinder/grinder.dart';

///
Future main(List<String> args) => grind(args);

/// If true some of the tests (notably) [unittest] run asynchronously.
bool runAsync = false;

/// Default task - runs if no arguments are given to grind.
@DefaultTask()
@Depends(analyze, unittest, format)
void defaultTask() {
  log('defaultTask');
}

/// This task is called from the convert/.git/hooks/pre-commit.bash.
@Task()
@Depends(analyze, unittest, format)
Future precommit() async {
  log('Pre-commit tasks');
}

/// Runs the Dart Analyzer
@Task('Analyzing Sources...')
void analyze() {
  log('Analyzing convert...');
  Analyzer.analyze(['bin', 'lib', 'test', 'tool'], fatalWarnings: true);
}

/// Runs all the unit tests in convert/test
@Task('Unit Testing...')
Future unittest() async {
  if (runAsync) {
    log('Unit Tests (running asynchronously)...');
    await new TestRunner().testAsync();
  } else {
    log('Unit Tests (running synchronously)...');
    new PubApp.local('test').run([]);
    // new TestRunner();
  }
}

/// Do a Dry Run of dartfmt.
@Task('Dry Run of Formating Source...')
void fmtdryrun() {
  log('Formatting Source...');
  DartFmt.dryRun('lib', lineLength: 80);
}

/// Format all dart sources in convert package.
@Task('Formating Source...')
void format() {
  log('Formatting Source...');
  DartFmt.format('.', lineLength: 80);
}

/// The default path for convert docs output
String dartDocPath = 'C:/odw/sdk/doc/convert';

/// The default directory for convert docs output
Directory dartDocDir = new Directory('C:/odw/sdk/doc/convert');

/// Generate Documentation for convert package.
@Task('DartDoc')
void tester() {
  log('Generating Documentation...');
  var s = sdkBin('dartdoc');
  s = s.replaceAll('\\', '/');
  print('$s');
}

/// Run dartdoc on convert and put in [dartDocPath].
@Task('DartDoc')
void dartdoc() {
  log('Generating Documentation...');
  run(sdkBin('dartdoc'), arguments: <String>[
    '--output=$dartDocPath',
    //   '--hosted-url http://localhost:8080',
    //   '--use-categories',
    '--show-progress'
  ]);
}

/// Build the convert package producing JavaScript files.
@Task('Build the project.')
//TODO: test
void build() {
  log('Building...');
  Pub.get();
  Pub.build(mode: 'debug');
}

//
/// Build and Release the convert
//TODO: test
@Task('Building release...')
void buildRelease() {
  log('Building release...');
  Pub.upgrade();
  Pub.build(mode: 'release');
}

/// Compile the convert package using Dart Development Compiler (dartdevc).
//TODO: install dartdevc and test when dartdevc has a beta release
@Task('Compiling...')
//@Depends(init)
void compile() {
  log('Dart Dev Compiler: Compiling...');
  const dartDevCOutPath = 'dart_dev_output';
  final dartDevCOutputDir = new Directory(dartDevCOutPath);
  new DevCompiler().compile('lib', dartDevCOutputDir);
}

/// Test the JavaScript files
@Task('Testing JavaScript...')
//TODO: test
//TODO: make sure this runs the .js files
@Depends(build)
void testJavaScript() {
  new PubApp.local('test').run([]);
}

/// Clean the convert package. Used before release.
@Task('Cleaning...')
void clean() {
  log('Cleaning...');
  delete(buildDir);
  delete(dartDocDir);
}

/// Deploy the convert package
@Task('Deploy...')
//TODO: test
//TODO: decide where this should be deployed to. GitHub, ACR, ...
@Depends(clean, format, compile, buildRelease, unittest, testJavaScript)
void deploy() {
  log('Deploying...');
  log('Regenerating Documentationfrom scratch...');
  delete(dartDocDir);
  dartdoc();
}
