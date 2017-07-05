// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/dicom_no_tag.dart';
import 'package:dictionary/dictionary.dart';

//import 'package:io/src/test/compare_files.dart';
String path0 = 'C:/odw/test_data/IM-0001-0001.dcm';
String path1 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255'
    '.393386351.1568457295.17895.5.dcm';
String path2 =
    'C:/odw/test_data/sfd/CR/PID_MINT10/1_DICOM_Original'
    '/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm';
String path3 =
    'C:/odw/test_data/sfd/CT/Patient_4_3_phase_abd/1_DICOM_Original'
    '/IM000002.dcm';
String path4 =
    'C:/odw/sdk/io/example/input'
    '/1.2.840.113696.596650.500.5347264.20120723195848/1.2'
    '.392.200036.9125.3.3315591109239.64688154694.35921044'
    '/1.2.392.200036.9125.9.0.252688780.254812416.1536946029.dcm';
String path5 =
    'C:/odw/sdk/io/example/input'
    '/1.2.840.113696.596650.500.5347264.20120723195848'
    '/2.16.840.1.114255.1870665029.949635505.39523.169'
    '/2.16.840.1.114255.1870665029.949635505.10220.175.dcm';
String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

final Logger log = new Logger("read_write_file", watermark: Severity.debug2);

void main(List<String> args) {
  File file = new File(path0);
  log.info('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.info('  ${bytes0.length} bytes');
  ByteDataset bds0 = ByteReader.readBytes(bytes0, path: file.path);
  log.info('Decoded: $bds0');
  if (bds0 == null) return null;
  log.debug(bds0.format(new Formatter(maxDepth: -1)));
  log.info('${bds0[kFileMetaInformationGroupLength].info}');
  log.info('${bds0[kFileMetaInformationVersion].info}');
  // Write a File
  File output = new File(outPath);
  var bytes = ByteWriter.writeBytes(bds0);
  output.writeAsBytesSync(bytes);

  log.info('Re-reading: $output');
  Uint8List bytes1 = output.readAsBytesSync();
  log.info('read ${bytes1.length} bytes');
  ByteDataset bds1 = ByteReader.readBytes(bytes1, path: file.path);
  log.info(bds1);
  log.debug(bds1.format(new Formatter(maxDepth: -1)));

  // Compare [Dataset]s
  var comparator = new DatasetComparitor(bds0, bds1);
  comparator.run;
  if (comparator.hasDifference) {
    log.fatal('Result: ${comparator.info}');
  }
/*
    // Compare input and output
    log.info('Comparing Bytes:');
    log.down;
    log.info('Original: ${fn.path}');
    log.info('Result: ${fnOut.path}');
    FileCompareResult out = compareFiles(fn.path, fnOut.path, log);
    if (out == null) {
        log.info('Files are identical.');
    } else {
        log.info('Files are different!');
        log.fatal('$out');
    }
    log.up;
*/
}
