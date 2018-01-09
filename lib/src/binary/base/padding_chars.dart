// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:system/core.dart';

const List<int> kPaddingByVRIndex = const <int>[
  // Sequence == 0
  -1,
  // EVR Long maybe undefined
  -1, -1, -1,
  // EVR Long
  -1, -1, -1, kSpace, kSpace, kSpace,
  // EVR Short
  kSpace, kSpace, -1, kSpace, kSpace, kSpace, kSpace,
  -1, -1, kSpace, kSpace, kSpace, kSpace, kSpace,
  -1, -1, kSpace, kSpace, kNull, -1, -1,
  // EVR Special
  -1, -1, -1, -1
];

int paddingChar(int vrIndex) => kPaddingByVRIndex[vrIndex];
