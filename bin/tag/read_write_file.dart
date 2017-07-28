// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/compare_bytes.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

void main() {
  final Logger log = new Logger("read_write_file", watermark: Severity.debug);
  DcmReader.log.watermark = Severity.debug;
  DcmWriter.log.watermark = Severity.debug;

  // *** Modify this line to read/write a different file
  var path = path0;

  log.info('Reading: $path');
  var reader0 = new TagReader.fromPath(path);
  RootTagDataset tagDS0 = reader0.readRootDataset();
  var bytes0 = reader0.bytes;
  log.debug('  Read ${bytes0.lengthInBytes} bytes');
  log.info('  DS0: $tagDS0');

  TagElement bpd = tagDS0[kPixelData];
  log.debug2('bpd: $bpd');
  if (bpd is OBPixelData) log.info(' VFFragments: ${bpd.fragments}');

  // Write a File
  var writer = new TagWriter.toPath(tagDS0, outPath);
  var bytes1 = writer.writeRootDataset();
  log.debug('  Wrote ${bytes1.length} bytes');

  log.info('Re-reading: $outPath');
  var reader1 = new TagReader.fromPath(path);
  var tagDS1 = TagReader.readPath(outPath);
  log.debug('  Read ${reader1.bd.lengthInBytes} bytes');
  log.info('  DS1: $tagDS1');

  if (tagDS0.parseInfo != tagDS1.parseInfo) {
    log.warn('  *** ParseInfo is Different!');
    log.debug('  ${tagDS0.parseInfo}');
    log.debug('  ${tagDS1.parseInfo}');
    log.debug2(tagDS0.format(new Formatter(maxDepth: -1)));
    log.debug2(tagDS1.format(new Formatter(maxDepth: -1)));
  }

  // Compare [Dataset]s
  if (reader0.elementList == writer.elementList) {
    log.info('ElementLists are identical.');
  } else {
    log.info('ElementLists are different!');
  }

  // Compare [Dataset]s
  if (tagDS0 == tagDS1) {
    log.info('Datasets are identical.');
  } else {
    log.info('Datasets are different!');
  }

  //   FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
  var same = bytesEqual(bytes0, bytes1, true);
  if (same == true) {
    log.info('Files are identical.');
  } else {
    log.info('Files are different!');
  }
}
