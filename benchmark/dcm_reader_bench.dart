// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

// Import BenchmarkBase class.
import 'package:benchmark_harness/benchmark_harness.dart';

import 'package:dcm_convert/src/dicom_no_tag/dcm_byte_reader.dart';
import 'package:dcm_convert/timer.dart';

import 'test_files.dart';



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
    readFileTest(file, reps: 20, fmiOnly: false);
  }

  // Not measured: setup code executed before the benchmark runs.
  @override
  void setup() {
    timer = new Timer();
    print('DcmReader benchmark start');
  }

  // Not measured: teardown code executed after the benchmark runs.
  @override
  void teardown() {
    timer.stop();
    var time = timer.elapsed;
    print('DcmReader benchmark end: $time');
  }
}

// Main function runs the benchmark.
void main() {
  // Run TemplateBenchmark.
  TemplateBenchmark.main();
}

void readFileTest(File inFile, {int reps = 1, bool fmiOnly = false}) {
  Uint8List bytes0 = inFile.readAsBytesSync();

  var timer = new Timer();
  for (int i = 0; i < reps; i++) {
    DcmByteReader.readBytes(bytes0);
  }
  timer.stop();
  print('readFileTest Time: ${timer.elapsed}');

}
