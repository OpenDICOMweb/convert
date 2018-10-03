//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

const List<int> kPaddingByVRIndex = <int>[
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
