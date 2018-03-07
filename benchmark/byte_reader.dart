// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'package:convert/convert.dart';
import 'package:core/server.dart';

import 'test_files.dart';
// Import BenchmarkBase class.

Timer timer;
Duration time;

// Create a new benchmark by extending BenchmarkBase.
class TemplateBenchmark extends BenchmarkBase {
  const TemplateBenchmark() : super('Template');

  static void main() {
    const TemplateBenchmark().report();
  }


  // The benchmark code.
  @override
  void run() {
    final file = new File(ivrle);
    readFileTest(file, reps: 20, fmiOnly: false);
  }

  // Not measured: setup code executed before the benchmark runs.
  @override
  void setup() {
    Server.initialize(name: 'dcm_writer_benchmark', level: Level.debug);
    timer = new Timer();
    print('DcmReader benchmark start');
  }

  // Not measured: teardown code executed after the benchmark runs.
  @override
  void teardown() {
    timer.stop();
    final time = timer.elapsed;
    print('DcmReader benchmark end: $time');
  }
}

// Main function runs the benchmark.
void main() {
  // Run TemplateBenchmark.
  TemplateBenchmark.main();
}

void readFileTest(File inFile, {int reps = 1, bool fmiOnly = false}) {
	final bytes0 = inFile.readAsBytesSync();
  final timer = new Timer();
  for (var i = 0; i < reps; i++) {
    BDReader.readBytes(bytes0);
  }
  timer.stop();
  print('readFileTest Time: ${timer.elapsed}');

}
