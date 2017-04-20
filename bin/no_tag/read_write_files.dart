// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:convertX/src/dicom_no_tag/compare_bytes.dart';
import 'package:path/path.dart' as p;

import 'utils.dart';

final Logger log =
new Logger("convert/bin/read_write_files.dart", watermark: Severity.warn);

String testData = "C:/odw/test_data";
String test6688 = "C:/odw/test_data/6688";
String mWeb = "C:/odw/test_data/mweb";

void main() {
  // readWriteFile(path0, fmiOnly: false);
  // readFMI(paths, fmiOnly: true);
  //  readWriteFiles(paths, fmiOnly: false);
  readDirectory(mWeb, fmiOnly: false);
  //targetTS: TransferSyntax.kImplicitVRLittleEndian);
}

void readWriteFiles(List<String> paths, {bool fmiOnly = false}) {
  for (String path in paths)
    readWriteFile(path);
}

bool readWriteFile(String path, {bool fmiOnly = false}) {
  File inFile = new File(path);
  Uint8List bytes0 = inFile.readAsBytesSync();
  if (bytes0 == null) log.error('Could not read "$path"');
  var rds0 = readFile(path);

  var base = p.basename(path);
  var outPath = 'bin/output/$base';
  Uint8List bytes1 = writeDataset(rds0, outPath);

 // log.info('Reading $outPath ...');
   var rds1 = readFile(outPath);
   if (rds0.total != rds1.total) {
     log.error('Unequal datasets:\n'
         '  rds0: ${rds0.total}\n'
         '  rds1: ${rds1.total}\n');
     return false;
   }

   if (!compareDatasets(rds0, rds1))
     log.error('****Datasets unequal');
   if (rds0 != rds1) {
     if (rds0.total != rds1.total) {
       log.error('Unequal datasets:\n'
           '  rds0: $rds0\n'
           '  rds1: $rds1\n');
       //TODO
       // rds.difference(rds1);
       return false;
     }
   }


  if (bytes0.lengthInBytes != bytes1.lengthInBytes) {
    log.error('Unequal length files:\n'
        '  bytes0: ${bytes0.lengthInBytes}\n'
        '  bytes1: ${bytes1.lengthInBytes}\n');

    if (!compareBytes(bytes0, bytes1)) {
      log.error('**** Bytes0 != Bytes1\n$path');
      return false;
    }
  }
  return true;
}


void readDirectory(String path,
    {bool fmiOnly = false, String fileExt = '.dcm'}) {
  Directory dir = new Directory(path);

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  int fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  List<String> files = <String>[];

  int total = 0;
  int good = 0;
  int bad = 0;
  for (FileSystemEntity fse in fList) {
    if (fse is File) {
      var path = fse.path;
      var ext = p.extension(path);
      if (fileExt == "" || ext == fileExt) {
        bool v = readWriteFile(path);
        total++;
        if (v) good++; else bad++;
        if (total % 100 == 0) print('$total files good($good) bad($bad)');
      }
    }
  }
  log.warn('$total files read\n'
      '  $good success\n'
      '  $bad  failure');
}

