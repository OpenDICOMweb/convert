// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/server.dart';

import 'package:convert/data/test_files.dart';
import 'package:convert/convert.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

void main() {
  Server.initialize(name: 'read_write_file.dart', level: Level.debug);

  // *** Modify this line to read/write a different file
  final path = path0;

  log.info('Reading: $path');
  final Uint8List bList = new File(path).readAsBytesSync();
  log.info('  File Length: ${bList.length}');
  final reader0 = new TagReader(bList, doLogging: true);
  final tagDS0 = reader0.readRootDataset();
  final a = reader0.rb.asBytes();
  log
    ..debug('  Read ${a.lengthInBytes} bytes')
    ..info0('  DS0: $tagDS0');

  final bpd = tagDS0[kPixelData];
  log.debug2('bpd: $bpd');
  if (bpd is OBPixelData) log.info0(' VFFragments: ${bpd.fragments}');

  // Write a File
  final writer = new TagWriter.toPath(tagDS0, outPath);
  final b = writer.writeRootDataset();
  log
    ..debug('  Wrote ${b.length} bytes')
    ..info0('Re-reading: $outPath');
  final Uint8List bList1 = new File(path).readAsBytesSync();
  final reader1 = new TagReader(bList1, doLogging: true);
  final tagDS1 = TagReader.readPath(outPath);
  log
    ..debug('  Read ${reader1.rb.lengthInBytes} bytes')
    ..info0('  DS1: $tagDS1');

  if (reader1.pInfo != reader1.pInfo) {
    log
      ..warn('  *** ParseInfo is Different!')
      ..debug('  ${reader1.pInfo}')
      ..debug('  ${reader1.pInfo}')
      ..debug2(tagDS0.format(new Formatter(maxDepth: -1)))
      ..debug2(tagDS1.format(new Formatter(maxDepth: -1)));
  }

  // Compare [Dataset]s
  if (reader0.offsets == writer.offsets) {
    log.info0('ElementOffsets are identical.');
  } else {
    log.info0('ElementOffsets are different!');
  }

  // Compare [Dataset]s
  if (tagDS0 == tagDS1) {
    log.info0('Datasets are identical.');
  } else {
    log.info0('Datasets are different!');
  }

  //   FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
  final same = a == b;
  if (same == true) {
    log.info0('Files are identical.');
  } else {
    log.info0('Files are different!');
  }
}
