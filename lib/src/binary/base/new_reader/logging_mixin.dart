// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

import 'package:core/core.dart';

abstract class LoggingMixin {
  ReadBuffer get rb;
  RootDataset get rds;
  int get count;

  // **** Logging Functions
  // TODO: create no_logging_mixin and logging_mixin
  
  void startElementMsg(int code, int eStart, int vrIndex, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    log..debug('>@R$eStart ${dcm(code)} $vrId($vrIndex) $len')..down;
  }

  
  void endElementMsg(Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    log..up..debug('<@R${rb.index} $eNumber: $e');
  }

  
  void startSQMsg(int code, int eStart, int vrIndex, int vfOffset, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    final tag = Tag.lookupByCode(code, vrIndex);
    if (tag.vrIndex != kSQIndex) log.warn('Read SQ with Non-Sequence Tag $tag');
    final msg = '>@R$eStart ${dcm(code)} $vrId($vrIndex) $len $tag';
    log.debug(msg);
  }

  
  void endSQMsg(SQ e) {
    final eNumber = '$count'.padLeft(4, '0');
    final msg = '<@R${rb.index} $eNumber: $e';
    log.debug(msg);
  }

  
  void startDatasetMsg(
      int eStart, String name, int delimiter, int vlf, Dataset ds) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final dLimit = (delimiter == 0) ? 'No Delimiter' : dcm(delimiter);
    log..debug('>@R$eStart $name $dLimit $len $ds', 1)..down;
  }

  
  void endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds) {
    log..up..debug('>@R$dsStart $name $dsBytes: $ds', -1);
  }

  
  void startReadRootDataset(int rdsStart, int length) =>
      log..debug('>@${rb.index} subReadRootDataset length($length) $rds')..down;

  
  void endReadRootDataset(RootDataset rds, RDSBytes dsBytes) {
    log..up..debug('>@${rb.index} subReadRootDataset $dsBytes $rds')
      ..debug('$count Elements read');
    if (rds[kPixelData] == null) log.info('** Pixel Data Element not present');
    if (rds.hasDuplicates) log.warn('** Duplicates Present in rds0');
  }


}