//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';

// ignore_for_file: public_member_api_docs

abstract class LoggingMixin {
  ReadBuffer get rb;
  RootDataset get rds;
  int get count;

  // **** Logging Functions
  // TODO: create no_logging_mixin and logging_mixin

  void startElementMsg(int code, int start, int vrIndex, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    log..debug('>@R$start ${dcm(code)} $vrId($vrIndex) $len')..down;
  }


  void endElementMsg(Element e) {
    final eNumber = '$count'.padLeft(4, '0');
    log..up..debug('<@R${rb.index} $eNumber: $e');
  }


  void startSQMsg(int code, int start, int vrIndex, int vfOffset, int vlf) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final vrId = vrIdByIndex[vrIndex];
    final tag = Tag.lookupByCode(code, vrIndex);
    if (tag.vrIndex != kSQIndex)
      log.warn('Read SQ with Non-Sequence Tag $tag');
    final msg = '>@R$start ${dcm(code)} $vrId($vrIndex) $len $tag';
    log.debug(msg);
  }


  void endSQMsg(SQ e) {
    final eNumber = '$count'.padLeft(4, '0');
    final msg = '<@R${rb.index} $eNumber: $e';
    log.debug(msg);
  }


  void startDatasetMsg(
      int start, String name, int delimiter, int vlf, Dataset ds) {
    final len = (vlf == kUndefinedLength) ? 'Undefined Length' : 'vfl: $vlf';
    final dLimit = (delimiter == 0) ? 'No Delimiter' : dcm(delimiter);
    log..debug('>@R$start $name $dLimit $len $ds', 1)..down;
  }


  void endDatasetMsg(int dsStart, String name, DSBytes dsBytes, Dataset ds) {
    log..up..debug('>@R$dsStart $name $dsBytes: $ds', -1);
  }


  void startReadRootDataset(int rdsStart, int length) =>
      log..debug('>@${rb.index} subReadRootDataset length($length) $rds')..down;


  void endReadRootDataset(RootDataset rds, RDSBytes dsBytes) {
    log..up..debug('>@${rb.index} subReadRootDataset $dsBytes $rds')
      ..debug('$count Elements read');
    if (rds[kPixelData] == null)
      log.info('** Pixel Data Element not present');
    if (rds.hasDuplicates)
      log.warn('** Duplicates Present in rds0');
  }


}
