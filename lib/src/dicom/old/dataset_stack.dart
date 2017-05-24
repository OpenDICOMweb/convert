// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

class DatasetStack {
  List<Dataset> stack = <Dataset>[];

  DatasetStack();

  Dataset get last => stack.last;

  Dataset get pop => stack.removeLast();

  int get length => stack.length;

  void push(Dataset ds) {
    stack.add(ds);
  }

  @override
  String toString() => '$runtimeType($length)}';
}
