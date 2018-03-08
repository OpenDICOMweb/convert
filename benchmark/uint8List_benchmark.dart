// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:core/server.dart';

import 'test_files.dart';
// Import BenchmarkBase class.

String path = ivrle;
final Uint8List uint8List = new File(path).readAsBytesSync();
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
    time += readUint8ListTest(reps: 10);
  }

  // Not measured: setup code executed before the benchmark runs.
  @override
  void setup() {
    Server.initialize(name: 'Uint8List Benchmark', level: Level.info);
    print('Uint8List length: ${uint8List.lengthInBytes}');
    timer = new Timer();
    time = new Duration(minutes: 0);
    print('Uint8List benchmark start: $time');
  }

  // Not measured: teardown code executed after the benchmark runs.
  @override
  void teardown() {
    timer.stop();
    final elapsed = timer.elapsed;
    print('Uint8List benchmark end: $time, elapsed: $elapsed');
  }
}

// Main function runs the benchmark.
void main() {
  // Run TemplateBenchmark.
  TemplateBenchmark.main();
}

Duration readUint8ListTest({int reps = 1}) {
  for (var i = 0; i < warmup; i++)
    for (var i = 0; i < uint8List.length; i++) {
      final n = uint8List[i];
      uint8List[i] = n;
    }
  final timer = new Timer()..start();
  for (var i = 0; i < loops; i++) {
    for (var i = 0; i < uint8List.length; i++) {
      final n = uint8List[i];
      uint8List[i] = n;
    }
  }
  timer.stop();

  print('  Read Uint8List Time: ${timer.elapsed}');
  return timer.elapsed;
}