// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dictionary/dictionary.dart';
import 'package:dcm_convert/src/dcm/compare_bytes.dart';
import 'package:dcm_convert/src/dcm/compare_dataset.dart';

import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Logger log = new Logger("read_write_file", watermark: Severity.debug);

void main() {
  var path = path2;

  DcmReader.log.watermark = Severity.debug;
  DcmWriter.log.watermark = Severity.debug;

  log.info('Reading: $path');
  var reader0 = new ByteReader.fromPath(path);
  var rbds0 = reader0.readRootDataset();
  var bytes0 = reader0.bytes;
  log.debug('  Read ${bytes0.lengthInBytes} bytes');
  log.info('  DS0: $rbds0');

  BytePixelData bpd = rbds0[kPixelData];
  log.info(' VFFragments: ${bpd.fragments}');

  // Write a File
  var writer = new ByteWriter.toPath(rbds0, outPath);
  var bytes1 = writer.writeRootDataset();
  log.debug('  Wrote ${bytes1.length} bytes');

  log.info('Re-reading: $outPath');
  var reader1 = new ByteReader.fromPath(path);
  var rbds1 = ByteReader.readPath(outPath);
  log.debug('  Read ${reader1.bd.lengthInBytes} bytes');
  log.info('  DS1: $rbds1');

  if (rbds0.parseInfo != rbds1.parseInfo) {
    log.warn('  *** ParseInfo is Different!');
    log.debug('  ${rbds0.parseInfo}');
    log.debug('  ${rbds1.parseInfo}');
    log.debug2(rbds0.format(new Formatter(maxDepth: -1)));
    log.debug2(rbds1.format(new Formatter(maxDepth: -1)));
  }

  // Compare [Dataset]s
  var same = reader0.elementList == writer.elementList;
  if (same == true) {
    log.info('ElementLists are identical.');
  } else {
    log.info('ElementLists are different!');
  }

  // Compare [Dataset]s
  same = compareDatasets(rbds0, rbds1, true);
  if (same == true) {
    log.info('Datasets are identical.');
  } else {
    log.info('Datasets are different!');
  }

  //   FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
  same = bytesEqual(bytes0, bytes1, true);
  if (same == true) {
    log.info('Files are identical.');
  } else {
    log.info('Files are different!');
  }
}
