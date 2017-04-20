// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/logger.dart';

import 'bad_files0.dart';
import 'read_file_list.dart';


String testData = "C:/odw/test_data";
String test6688 = "C:/odw/test_data/6688";
String mWeb = "C:/odw/test_data/mweb";


final Logger log =
    new Logger("io/bin/read_file.dart", watermark: Severity.info);

const List<String> defaultList = fileList0;

void main() {
 // readPath(badIvrle, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
 //  readFiles(badFiles1, fmiOnly: false);
   readDirectory(test6688, fmiOnly: false);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

void readFiles(List<String> paths, {bool fmiOnly = true}) {
  /*
  log.info('Started Reading ${paths.length} files...');
  var timer = new Stopwatch();
  var timestamp = new Timestamp();
  timer.start();
  log.info('   at: $timestamp');
  */
  var reader = new FileListReader(paths, fmiOnly: fmiOnly, printEvery: 100);
  reader.read;
  /*
  timer.stop();
  log.info('Elapsed time: ${timer.elapsed}');
  */
}
