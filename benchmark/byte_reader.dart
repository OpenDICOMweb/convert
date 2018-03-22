// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:convert/convert.dart';
import 'package:core/server.dart';

//import 'package:convert/data/test_files.dart';

const String f6684a =
    'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';

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
    readFileTest(f6684a, reps: 20, fmiOnly: false);
  }

  // Not measured: setup code executed before the benchmark runs.
  @override
  void setup() {
    Server.initialize(name: 'ByteReader benchmark', level: Level.info);
    timer = new Timer();
    print('ByteReader benchmark start');
  }

  // Not measured: teardown code executed after the benchmark runs.
  @override
  void teardown() {
    timer.stop();
    final time = timer.elapsed;
    print('ByteReader benchmark end: $time');
  }
}

// Main function runs the benchmark.
void main() {
  // Run TemplateBenchmark.
  TemplateBenchmark.main();
}

void readFileTest(String path, {int reps = 1, bool fmiOnly = false}) {
	final bytes = Bytes.fromPath(path);
  final timer = new Timer();
  for (var i = 0; i < reps; i++) {
    ByteReader.readBytes(bytes, doLogging: false, showStats: true);
  }
  timer.stop();
  print('readFileTest Time: ${timer.elapsed}');

}
