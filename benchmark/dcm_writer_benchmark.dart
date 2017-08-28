// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:system/server.dart';
import 'package:timer/timer.dart';


import 'test_files.dart';
// Import BenchmarkBase class.

Timer timer;
Duration time;

// Create a new benchmark by extending BenchmarkBase.
class TemplateBenchmark extends BenchmarkBase {
    const TemplateBenchmark() : super("Template");

    static void main() {
        new TemplateBenchmark().report();
    }


    // The benchmark code.
    @override
    void run() {
      File file = new File(ivrle);
      writeFileTest(file, reps: 20, fmiOnly: false);
    }

    // Not measured: setup code executed before the benchmark runs.
    @override
    void setup() {
      Server.initialize(name: 'dcm_writer_benchmark', level: Level.info0);
      timer = new Timer();
      print('DcmWriter benchmark start');
    }

    // Not measured: teardown code executed after the benchmark runs.
    @override
    void teardown() {
      timer.stop();
      var time = timer.elapsed;
      print('DcmWriter Benchmark Time: $time');
      print('finished');
    }
}

// Main function runs the benchmark.
void main() {
    // Run TemplateBenchmark.
    TemplateBenchmark.main();
}

bool writeFileTest(File inFile, {int reps = 1, bool fmiOnly = false}) {
  Uint8List bytes0 = inFile.readAsBytesSync();
  RootByteDataset rds0 = ByteReader.readBytes(bytes0);
  Uint8List bytes1 = ByteWriter.writeBytes(rds0, fast: true, path: "");
  if (!bytesEqual(bytes0, bytes1)) throw "Error in DcmWrite";

  var timer = new Timer();
  for (int i = 0; i < reps; i++) {
    ByteWriter.writeBytes(rds0, fast: true, path: "");
  }

  print('writeFileTest Time: ${timer.elapsed}');
  timer.stop();
  return true;
}

