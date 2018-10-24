//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
import 'package:core/core.dart';

const List<int> kPaddingByVRIndex = <int>[
  kSpace, // UN == 0
  -1,   // Sequence == 1

  // EVR Long maybe undefined
  -1, -1,      // OB, OW
  // EVR Long binary
  -1, -1, -1,  // OD, OF, OL
  // Evr Long String
  kSpace, kSpace, kSpace,
  // EVR Short
  kSpace, kSpace, kSpace,
  kSpace, kSpace, kSpace,
  kSpace, kSpace, kSpace,
  kSpace, kSpace, kSpace,
  kSpace, kNull,

  // EVR Short Binary
  -1, -1, -1,
  -1, -1, -1,
  -1,
  // EVR Special
  -1, -1, -1, -1,
];

int paddingChar(int vrIndex) => kPaddingByVRIndex[vrIndex];
