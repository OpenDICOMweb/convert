// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/byte_data_tools.dart';
import 'package:core/server.dart';

//import 'package:dcm_convert/data/test_directories.dart';


//TODO: On error write the log file to dir/output/name.log where name if path
// - dir (i.e. remove the prefix dir and replace with dir/output.
//TODO: create results.log with summary of run including errors.
//TODO: if an error occurs rerun the file with debug setting and store
//      output in filename.log
// TODO: print out the version numbers of the different packages.
//TODO: better doc

/// A program for doing read/write/read testing on DICOM files.
void main(List<String> args) {
  Server.initialize(name: 'read_write_file', level: Level.warn1, throwOnError: true);

  /// The processed arguments for this program.
  final jobArgs = new JobArgs(args);

  print('jobArgs: ${jobArgs.summary}');

  if (jobArgs.showHelp) showHelp(jobArgs);

  JobRunner.job(jobArgs, doReadByteFile,
      interval: jobArgs.shortMsgEvery, level: jobArgs.baseLevel);
}

/// The help message
void showHelp(JobArgs jobArgs) {
  final msg = '''
Usage: readdir <input-directory> [<options>]

Tries to read each each file in the <directory> tree. If successful, infomation
about the Dataset contained in the file is printed.
  
Options:
${jobArgs.parser.usage}
''';
  stdout.write(msg);
  exit(0);
}
