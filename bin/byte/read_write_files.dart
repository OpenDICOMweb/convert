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

import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Logger log = new Logger("read_write_file", watermark: Severity.config);

void main() {
  List<String> paths = testPaths;

  DcmReader.log.watermark = Severity.info;
  DcmWriter.log.watermark = Severity.info;

  for (int i = 0; i < paths.length; i++) {
    File f = new File(paths[i]);
    try {
      readWriteFileCheck(f, i);
    } on ShortFileError {
      log.warn('Short File(${f.lengthSync()} bytes): $f');
    } catch (e) {
      log.error(e);
    }
    log.reset;
  }
}

bool readWriteFileCheck(File file, int fileNo) {
  var bytes0 = file.readAsBytesSync();
  log.config('$fileNo: Reading: $file with ${bytes0.length} bytes');

  log.down;
  var rbds0 = ByteReader.readBytes(bytes0);
  if (rbds0 == null) {
    log.warn('---  File not readable');
    return false;
  } else {
    log.info('${rbds0.parseInfo.info}');
    log.debug('Bytes Dataset: ${rbds0.info}');
  }

  log.debug(': $rbds0');
  log.debug('parseInfo: ${rbds0.parseInfo}');
  log.debug1('${rbds0[kFileMetaInformationGroupLength].info}');
  log.debug1('${rbds0[kFileMetaInformationVersion].info}');
  log.debug2(rbds0.format(new Formatter(maxDepth: -1)));

  // Write to [outPath]
  log.info('Writing: $outPath');
  var bytes1 = ByteWriter.writePath(rbds0, outPath, overwrite: true);

  log.info('Re-reading: $outPath');
  var rbds1 = ByteReader.readPath(outPath);
  log.debug(rbds1);
  log.debug1(rbds1.format(new Formatter(maxDepth: -1)));

  // Compare [Dataset]s
  var same = compareDatasets(rbds0, rbds1);
  if (same == true) {
    log.info('Comparing Datasets: identical.');
  } else {
    log.warn('Comparing Datasets: different! ***');
  }

  //   FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
  log.info('Comparing Bytes');
  var good = bytesEqual(bytes0, bytes1);

  log.down;
  if (good == true) {
    log.info('Identical.');
  } else {
    log.warn('*** Bytes are Different!');
  }
  log.up;
  log.info('---\n');
  log.up;
  return good;

}