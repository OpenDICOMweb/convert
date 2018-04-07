// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'package:core/core.dart';

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


