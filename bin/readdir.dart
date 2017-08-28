// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/tools.dart';
import 'package:system/server.dart';

import 'package:dcm_convert/data/test_directories.dart';

//TODO: improve performance
//TODO: On error write the log file to dir/output/name.log where name if path
// - dir (i.e. remove the prefix dir and replace with dir/output.
//TODO: create results.log with summary of run including errors.
//TODO: if an error occurs rerun the file with debug setting and store
//      output in filename.log
// TODO: print out the version numbers of the different packages.
//TODO: better doc

const defaultDirectory = 'C:/odw/test_data/sfd/MG';

/// A program for doing read/write/read testing on DICOM files.
void main(List<String> args) {
  Server.initialize(name: 'read_write_file', level: Level.error);

  /// The processed arguments for this program.
  JobArgs jobArgs = new JobArgs(args);

  if (jobArgs.showHelp) showHelp(jobArgs);

  // Get target directory and validate it.
  var dirName;
  if (args.length == 0) {
    stderr.write('No Directory name supplied - defaulting to C:/odw/test_data\n');
    // **** change this name when testing
    dirName = 'C:/odw/test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original';
  } else {
    dirName = args[0];
  }

  var dir = toDirectory(dirName);
  if (dir == null) {
    if (dirName[0] == '-') {
      stderr.write('Error: Missing directory argument - "$dir"');
    } else {
      stderr.write('Error: $dirName does not exist');
    }
    exit(-1);
  }



  // Short circuit arguments for testing
 // dir = new Directory(dir6688);
  dir = new Directory(sfd);
  jobArgs.shortMsgEvery = 1000;
  system.log.level = Level.error;

  JobRunner.job(dir, doReadByteFile,
      interval: jobArgs.shortMsgEvery, level: jobArgs.baseLevel);
}

/// The help message
void showHelp(JobArgs jobArgs) {
  var msg = '''
Usage: readdir <input-directory> [<options>]

Tries to read each each file in the <directory> tree. If successful, infomation
about the Dataset contained in the file is printed.
  
Options:
${jobArgs.parser.usage}
''';
  stdout.write(msg);
  exit(0);
}
