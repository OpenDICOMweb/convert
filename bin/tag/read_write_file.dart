// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.


import 'dart:io';

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/compare_bytes.dart';
import 'package:dcm_convert/src/dcm/compare_dataset.dart';
import 'package:dictionary/dictionary.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Logger log = new Logger("read_write_file", watermark: Severity.debug2);

void main() {
  var path = path0;
  log.info('Reading: $path');
  var inFile = new File(path);
  var bytes0 = inFile.readAsBytesSync();
  var rbds0 = TagReader.readPath(path);
  log.info(': $rbds0');
  log.info('parseInfo: ${rbds0.parseInfo}');
  log.debug2('${rbds0[kFileMetaInformationGroupLength].info}');
  log.debug2('${rbds0[kFileMetaInformationVersion].info}');
  log.debug1(rbds0.format(new Formatter(maxDepth: -1)));

  // Write a File
  var bytes1 = TagWriter.writePath(rbds0, outPath, overwrite: true);
  log.info('Re-reading: $outPath');
  var rbds1 = TagReader.readPath(outPath);
  log.info(rbds1);
  log.debug1(rbds1.format(new Formatter(maxDepth: -1)));

  // Compare [Dataset]s
  var same = compareDatasets(rbds0, rbds1);
  if (same == true) {
    log.info('Datasets are identical.');
  } else {
    log.info('Datasets are different!');
  }

  //   FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
  var good = bytesEqual(bytes0, bytes1);
  if (good == true) {
    log.info('Files are identical.');
  } else {
    log.info('Files are different!');
  }
}
