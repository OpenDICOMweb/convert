// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:core/server.dart';

import 'test_files.dart';
// Import BenchmarkBase class.

String path = ivrle;
final Bytes bytes = Bytes.fromPath(path);
int warmup = 4;
int loops = 10;
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
    time += readBytesTest(reps: 10);
  }

  // Not measured: setup code executed before the benchmark runs.
  @override
  void setup() {
    Server.initialize(name: 'bytes_benchmark', level: Level.info);
    print('Bytes length: ${bytes.lengthInBytes}');
    timer = new Timer();
    time = new Duration(minutes: 0);
    print('Bytes benchmark start: $time');
  }

  // Not measured: teardown code executed after the benchmark runs.
  @override
  void teardown() {
    timer.stop();
    final elapsed = timer.elapsed;
    print('ByteData benchmark end: $time, elapsed: $elapsed');
  }
}

// Main function runs the benchmark.
void main() {
  // Run TemplateBenchmark.
  TemplateBenchmark.main();
}

Duration readBytesTest({int reps = 1}) {

  for (var i = 0; i < warmup; i++)
    for (var i = 0; i < bytes.length; i++) {
      final n = bytes[i];
      bytes[i] = n;
    }

  final timer = new Timer()..start();
  for (var i = 0; i < loops; i++) {
    for (var i = 0; i < bytes.length; i++) {
      final n = bytes[i];
      bytes[i] = n;
    }
  }
  timer.stop();

  print('  Read Bytes Time: ${timer.elapsed}');
  return timer.elapsed;
}
