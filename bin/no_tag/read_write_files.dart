// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:path/path.dart' as p;

import 'test_files.dart';
import 'utils.dart';

final Logger log =
new Logger("convert/bin/read_write_files.dart", watermark: Severity.info);

void main() {
   readWriteReadFile(path0, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readFiles(badFiles1, fmiOnly: false);
  //readDirectory(test6688, fmiOnly: false);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

void readWriteReadFile(String path, {bool fmiOnly = false}) {
  File inFile = new File(path);
  Uint8List bytes0 = inFile.readAsBytesSync();
  if (bytes0 == null) log.error('Could not read "$path"');
  var rds0 = readFile(path);

  var base = p.basename(path);
  var outPath = 'bin/output/$base';
  Uint8List bytes1 = writeDataset(rds0, outPath);


  if (bytes0.lengthInBytes != bytes1.lengthInBytes) {
    log.error('Unequal length files:\n'
        '  bytes0: ${bytes0.lengthInBytes}\n'
        '  bytes1: ${bytes1.lengthInBytes}\n');
  }

   var rds1 = readFile(outPath);
   if (rds0.total != rds1.total) {
     log.error('Unequal datasets:\n'
         '  rds0: ${rds0.total}\n'
         '  rds1: ${rds1.total}\n');
   }
}
