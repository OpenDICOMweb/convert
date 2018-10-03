//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

// ignore_for_file: Type_Annotate_public_APIs

// Urgent Sharath:
// please create test files for
abstract class TestFileBase {
  final int eCount;
  final int sqCount;
  final int privateCount;

  const TestFileBase(this.eCount, this.sqCount, this.privateCount);

  TransferSyntax get ts;
  String get fPath;
}

class IvrTestFile extends TestFileBase {
  @override
  final String fPath;

  const IvrTestFile(int eCount, int sqCount, int privateCount, this.fPath)
      : super(eCount, sqCount, privateCount);

  @override
  TransferSyntax get ts => TransferSyntax.kImplicitVRLittleEndian;

  static IvrTestFile f1 = const IvrTestFile(-1, -1, -1, '');
}

class EvrTestFile extends TestFileBase {
  @override
  final String fPath;

  const EvrTestFile(int eCount, int sqCount, int privateCount, this.fPath)
      : super(eCount, sqCount, privateCount);

  @override
  TransferSyntax get ts => TransferSyntax.kExplicitVRLittleEndian;

  static EvrTestFile f1 = const EvrTestFile(-1, -1, -1, '');
}

class JpegTestFile extends TestFileBase {
  @override
  final String fPath;

  const JpegTestFile(int eCount, int sqCount, int privateCount, this.fPath)
      : super(eCount, sqCount, privateCount);

  @override
  TransferSyntax get ts => TransferSyntax.kJpeg2000ImageCompression;

  static EvrTestFile f1 = const EvrTestFile(-1, -1, -1, '');
}
