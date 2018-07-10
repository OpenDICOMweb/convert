//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

// import 'package:core/core.dart';

// ignore_for_file: Type_Annotate_public_APIs

// Urgent Sharath:
// please create test studies for tests
class TestStudy {
  final String studyUid;
  final int eCount;
  final int sqCount;
  final int privateCount;
  final String path;


  const TestStudy(this.studyUid,
      this.eCount, this.sqCount, this.privateCount, this.path);

  static const f1 = const TestStudy('0.1.2', -1, -1, -1, '');

}


