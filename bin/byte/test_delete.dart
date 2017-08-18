// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:system/system.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';

/// A Program that reads a [File], decodes it into a [RootByteDataset],
/// and then converts that into a [RootTagDataset].
void main() {
  System.log.level = Level.info;

  // Edit this line
  var path = path0;

  File f = toFile(path, mustExist: true);
  log.debug2('Reading: $f');
  RootByteDataset bRoot = ByteReader.readFile(f, fast: true);
  log.debug('bRoot.isRoot: ${bRoot.isRoot}');

  log.info0('patientID: "${bRoot.patientId}"');
  List<ByteElement> eList = bRoot.remove(kPatientID);
  log.info0('removed: $eList');
  if (bRoot[kPatientID] != null)
    log.error('kPatientID not removed: $eList');
  log.info0('patientID: "${bRoot[kPatientID]}"');
  log.info0('patientID: "${bRoot.patientId}"');

}
