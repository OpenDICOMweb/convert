//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

// ignore_for_file: public_member_api_docs

mixin NoLoggingMixin {
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
