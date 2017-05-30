// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:convertX/dicom.dart';
import 'package:convertX/dicom_no_tag.dart';
import 'package:convertX/src/dicom_no_tag/convert.dart';


const String path0 = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';
const String path1 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String path2 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String path3 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';
const String path4 = 'C:/odw/test_data/mweb/100 MB Studies';

Logger log = new Logger('convert_test', watermark: Severity.debug2);

void main() {
  for (String path in [path0]) {
    try {
      File f = new File(path);
/*      FileResult r = readFileWithResult(f, fmiOnly: false);
      if (r == null) {
        log.config('No Result');
      } else {
        log.config('${r.info}');
      }*/
      convert(f, fmiOnly: false);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}


bool convert(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.info('Reading: $file with ${bytes0.lengthInBytes} bytes');
  if (bytes0 == null) return false;

  RootByteDataset rds0 =
  DcmByteReader.readBytes(bytes0, path: file.path, fast: true);
  if (rds0 == null) return false;

  var converter = new DSConverter(rds0);
  RootTDataset rds1 = converter.run();

  // Test dataset equality
  if (rds0.length != rds1.length) throw "";
  if (rds0.total != rds1.total) throw "";
  log.info(rds1.info);

  // write out converted dataset and compare the bytes
  //Urgent: make this work
//  Uint8List bytes1 = DcmWriter.write(rds1, fast: true);
//  if (bytes1 == null) return false;
//  bytesEqual(bytes0, bytes1);

  return rds0 == rds1;
}
