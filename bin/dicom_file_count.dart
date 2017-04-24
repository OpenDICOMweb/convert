// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:path/path.dart' as p;
//import 'package:args/args.dart';


// Fix or remove
//ArgParser getParser() {

//}

String inRoot0 = "C:/odw/test_data/sfd/CR";
String inRoot1 = "C:/odw/test_data/sfd/CR_and_RF";
String inRoot2 = "C:/odw/test_data/sfd/CT";
String inRoot3 = "C:/odw/test_data/sfd/MG";
String inRoot4 = "C:/odw/test_data/sfd";
String inRoot5 = "C:/odw/test_data";
String inRoot6 = "C:/odw/test_data/mweb";

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

Logger log = new Logger("read_a_directory", watermark: Severity.info);

void main() {

    List<Directory> dirs = getDirectories(inRoot5);
    int count = 0;
    for(Directory dir in dirs) {
      log.info('  $dir');
      count += getDcmFileCount(dir);
    }
    print('count: $count');
}

List<FileSystemEntity> getAllFSEntities(String path) {
  Directory dir = new Directory(path);
  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  log.info('$dir has ${fList.length} entities');
  return fList;
}

List<Directory> getDirectories(String path) {
  Directory dir = new Directory(path);
  List<FileSystemEntity> fList = dir.listSync(recursive: false);
  List<Directory> dirs = <Directory>[];
  for (FileSystemEntity fse in fList) {
    if (fse is Directory) dirs.add(fse);
  }
  log.info('Subdirectories: ${dirs.length}');
  return dirs;
}

int getDcmFileCount(Directory dir) {
  int fsEntityCount;
  int filesCount;

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;

  List<File> files = <File>[];
  for (FileSystemEntity fse in fList) {
    if (fse is File) {
      var path = fse.path;
      var ext = p.extension(path);
      if (ext == '.dcm') {
        files.add(fse);
      }
    }
  }
  filesCount = files.length;
  log.info('    FSEntities: $fsEntityCount');
  log.info('    DICOM Files: $filesCount');
  return files.length;
}

