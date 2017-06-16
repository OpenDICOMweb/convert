// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:args/args.dart';
import 'package:core/core.dart';

void main() {
   var s1 = "simple string";
   var s2 = 'split\\string';

   var list1 = s1.split('\\');
   print('list: $list1');
   var list2 = s2.split('\\');
   print('list2: $list2');

}
