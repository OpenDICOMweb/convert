// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

class Indenter {
  int _amount = 0;
  final int increment;

  Indenter([this.increment = 2]);

  String get indent => "".padRight(_amount, ' ');

  String get down {
    _amount += increment;
    return indent;
  }

  String get up {
    final s = indent;
    _amount -= increment;
    return s;
  }
}
