// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

// Import BenchmarkBase class.
import 'package:benchmark_harness/benchmark_harness.dart';

// Create a new benchmark by extending BenchmarkBase.
class TemplateBenchmark extends BenchmarkBase {
    const TemplateBenchmark() : super("Template");

    static void main() {
        new TemplateBenchmark().report();
    }

    // The benchmark code.
    @override
    void run() {
    }

    // Not measured: setup code executed before the benchmark runs.
    @override
    void setup() { }

    // Not measured: teardown code executed after the benchmark runs.
    @override
    void teardown() { }
}

// Main function runs the benchmark.
void main() {
    // Run TemplateBenchmark.
    TemplateBenchmark.main();
}