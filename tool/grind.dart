// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:grinder/grinder.dart';

Future main(List<String> args) => grind(args);

/// The dartdoc [Directory].
Directory dartDocDir = new Directory('doc/api');

@DefaultTask('Running Default Tasks...')
void myDefault() {
  log('Running Grind Defaults...');
  log('  Running Tests...');
  test();
  log('  Running format...');
  format();
}

@Task('Testing Dart...')
void test() {
  new PubApp.local('test').run(<String>[]);
}

@Task('Cleaning...')
void clean() {
  log("Cleaning...");
  delete(buildDir);
  delete(dartDocDir);
}

@Task('Dry Run of Formating Source...')
void testformat() {
  log("Test Formatting Source...");
  DartFmt.dryRun('lib', lineLength: 80);
  // DartFmt.dryRun('bin', lineLength: 80);
  DartFmt.dryRun('example', lineLength: 80);
  DartFmt.dryRun('test', lineLength: 80);
  DartFmt.dryRun('tool', lineLength: 80);
}

@Task('Formating Source...')
void format() {
  log("Formatting Source...");
  DartFmt.format('lib', lineLength: 80);
  // DartFmt.format('bin', lineLength: 80);
  DartFmt.format('example', lineLength: 80);
  DartFmt.format('test', lineLength: 80);
  DartFmt.format('tool', lineLength: 80);
}

@Task('DartDoc')
void dartdoc() {
  log('Generating Documentation...');
  DartDoc.doc();
}

@Task('Build the project.')
void build() {
  log("Building...");
  Pub.get();
  Pub.build(mode: "debug");
}

@Task('Building release...')
void buildRelease() {
  log("Building release...");
  Pub.upgrade();
  Pub.build(mode: "release");
}

@Task('Compiling...')
//@Depends(init)
void compile() {
  log("Compiling...");
}

@Task('Testing JavaScript...')
@Depends(build)
void testJavaScript() {
  new PubApp.local('test').run(<String>[]);
}

@Task('Deploy...')
@Depends(clean, format, compile, buildRelease, test, testJavaScript)
void deploy() {
  log("Deploying...");
  log('Regenerating Documentationfrom scratch...');
  delete(dartDocDir);
  DartDoc.doc();
}
