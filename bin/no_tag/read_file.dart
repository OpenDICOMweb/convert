// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';

import 'bad_files0.dart';
import 'read_utils.dart';
import '../../benchmark/test_files.dart';

String testData = "C:/odw/test_data";
String test6688 = "C:/odw/test_data/6688";
String mWeb = "C:/odw/test_data/mweb";
String mrStudy = "C:/odw/test_data/mweb/100 MB Studies/MRStudy";


final Logger log =
    new Logger("io/bin/read_file.dart", watermark: Severity.info);

const List<String> defaultList = fileList0;

void main() {
  File f = new File(path0);
  FileResult r = readFileWithResult(f, fmiOnly: false);
  print(r.info);
 //  readFiles(fileList1, fmiOnly: false);
   //readDirectory(mrStudy, fmiOnly: false);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

