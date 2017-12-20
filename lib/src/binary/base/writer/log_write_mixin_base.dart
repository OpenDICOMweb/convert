// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:element/element.dart';

// The methods below are prototypes for supplying

abstract class LogWriteMixinBase {

  void logStartWrite(int eStart, Element e, String name) {}

  void logEndWrite(int eStart, Element e, String name, {bool ok = true}) {}

  void logStartSQWrite(int eStart, Element e, String name) {}

  void logEndSQWrite(int eStart, Element e, String name, {bool ok = true}) {}
}
