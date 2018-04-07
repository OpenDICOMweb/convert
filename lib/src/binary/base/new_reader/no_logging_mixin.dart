// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'package:core/core.dart';

class NoLoggingMixin {
  // **** Logging Functions
  // TODO: create nologgingmixin and loggingmixin
  void startElementMsg(int code, int eStart, int vrIndex, int vlf) {}

  void endElementMsg(Element e) {}

  void startSQMsg(int code, int eStart, int vrIndex, int vfOffset, int vlf) {}

  void endSQMsg(SQ e) {}

  void startDatasetMsg(
      int eStart, String name, int delimiter, int vlf, Dataset ds) {}

  void endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds) {}

  void startReadRootDataset(int rdsStart, int length) {}

  void endReadRootDataset(RootDataset rds, RDSBytes dsBytes) {}
}
