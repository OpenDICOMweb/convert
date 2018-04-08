// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'package:core/core.dart';

// ignore_for_file: Type_Annotate_public_APIs

// Urgent Sharath:
// please create test files for
abstract class TestFileBase {
  final int eCount;
  final int sqCount;
  final int privateCount;


  const TestFileBase(
      this.eCount, this.sqCount, this.privateCount);

  TransferSyntax get  ts;
  String get  fPath;
}

class IvrTestFile extends TestFileBase {
  @override
  final TransferSyntax ts = TransferSyntax.kImplicitVRLittleEndian;
  @override
  final String fPath;

  const IvrTestFile(int eCount, int sqCount, int privateCount,
      this.fPath) : super(eCount, sqCount,  privateCount);

  static const f1 = const IvrTestFile(-1, -1, -1, '');

}

class EvrTestFile extends TestFileBase {
  @override
  final TransferSyntax ts = TransferSyntax.kExplicitVRLittleEndian;
  @override
  final String fPath;

  const EvrTestFile(int eCount, int sqCount, int privateCount,
      this.fPath) : super(eCount, sqCount,  privateCount);

  static const f1 = const EvrTestFile(-1, -1, -1, '');

}

class JpegTestFile extends TestFileBase {
  @override
  final TransferSyntax ts = TransferSyntax.kJpeg2000ImageCompression;
  @override
  final String fPath;

  const JpegTestFile(int eCount, int sqCount, int privateCount,
      this.fPath) : super(eCount, sqCount,  privateCount);

  static const f1 = const EvrTestFile(-1, -1, -1, '');

}

