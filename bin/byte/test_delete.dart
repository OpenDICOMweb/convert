// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/byte_convert.dart';
import 'package:system/core.dart';

/// A Program that reads a [File], decodes it into a [RootDatasetByte],
/// and then converts that into a [RootDataset].
void main() {
  system.log.level = Level.info;

  // Edit this line
  final path = path0;

  final f = pathToFile(path, mustExist: true);
  log.debug2('Reading: $f');
  final rds = ByteDatasetReader.readFile(f, fast: true);
  final eList = rds.remove(kPatientID);
  log..debug('bRoot.isRoot: ${rds.isRoot}')
  ..info0('patientID: "${rds.patientId}"')

  ..info0('removed: $eList');
  if (rds[kPatientID] != null)
    log..error('kPatientID not removed: $eList')
  ..info0('patientID: "${rds[kPatientID]}"')
  ..info0('patientID: "${rds.patientId}"');

}
