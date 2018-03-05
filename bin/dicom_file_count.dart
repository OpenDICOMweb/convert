// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/server.dart';
import 'package:path/path.dart' as p;


String inRoot0 = 'C:/odw/test_data/sfd/CR';
String inRoot1 = 'C:/odw/test_data/sfd/CR_and_RF';
String inRoot2 = 'C:/odw/test_data/sfd/CT';
String inRoot3 = 'C:/odw/test_data/sfd/MG';
String inRoot4 = 'C:/odw/test_data/sfd';
String inRoot5 = 'C:/odw/test_data';
String inRoot6 = 'C:/odw/test_data/mweb';

String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

const String k6684 = 'C:/acr/odw/test_data/6684';
const String k6688 = 'C:/acr/odw/test_data/6688';
const String dir6684_2017_5 = 'C:/acr/odw/test_data/6684/2017/5/12/16/0EE11F7A';

Logger log = new Logger('read_a_directory', Level.info);

void main() {

    final dirs = getDirectories(dir6684_2017_5);
    var count = 0;
    for(var dir in dirs) {
      log.info0('  $dir');
      count += getDcmFileCount(dir);
    }
    print('count: $count');
}

List<FileSystemEntity> getAllFSEntities(String path) {
	final dir = new Directory(path);
	final fList = dir.listSync(recursive: true);
  log.info0('$dir has ${fList.length} entities');
  return fList;
}

List<Directory> getDirectories(String path) {
	final dir = new Directory(path);
	final fList = dir.listSync(recursive: false);
	final dirs = <Directory>[];
  for (var fse in fList) {
    if (fse is Directory) dirs.add(fse);
  }
  log.info0('Subdirectories: ${dirs.length}');
  return dirs;
}

int getDcmFileCount(Directory dir) {
  int fsEntityCount;
  int filesCount;

  final fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;

  final files = <File>[];
  for (var fse in fList) {
    if (fse is File) {
	    final path = fse.path;
	    final ext = p.extension(path);
      if (ext == '.dcm') {
        files.add(fse);
      }
    }
  }
  filesCount = files.length;
  log..info0('    FSEntities: $fsEntityCount')
  ..info0('    DICOM Files: $filesCount');
  return files.length;
}


