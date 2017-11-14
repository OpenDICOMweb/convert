// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/tools.dart';
import 'package:system/server.dart';

//import 'package:dcm_convert/data/test_directories.dart';

//TODO: improve performance
//TODO: On error write the log file to dir/output/name.log where name if path
// - dir (i.e. remove the prefix dir and replace with dir/output.
//TODO: create results.log with summary of run including errors.
//TODO: if an error occurs rerun the file with debug setting and store
//      output in filename.log
// TODO: print out the version numbers of the different packages.
//TODO: better doc

const String defaultDirectory = 'C:/odw/test_data/sfd/MG';
const String mWeb1000 = 'C:/odw/test_data/mweb/1000+';

final List<String> defaultArgs = ['$mWeb1000'];

/// A program for doing read/write/read testing on DICOM files.
void main(List<String> args) {
  Server.initialize(name: 'read_write_file', level: Level.info);

  final xArgs =  (args.isEmpty) ? defaultArgs : args;

  /// The processed arguments for this program.
  final jobArgs = new JobArgs(xArgs);

  if (jobArgs.showHelp) showHelp(jobArgs);

  JobRunner.job(jobArgs, doRWFile,
      interval: jobArgs.shortMsgEvery, level: jobArgs.baseLevel);
}

/// The help message
void showHelp(JobArgs jobArgs) {
	final msg = '''
Usage: rwrdir <input-directory> [<options>]

For each application/dicom file in the <directory> tree:
  1. Decodes (reads) the data in a byte array (file) into a Root Dataset [0]
  2. Encodes (writes) the Root Dataset into a new byte array
  3. Decodes (reads) the new bytes array (file) into a new Root Dataset [1]
  4. It than compares the ElementOffsetss, Datasets, and bytes arrays to 
    determine whether the writter and re-read Dataset and bytes are equivalent
    to the original byte array that was read in step 1.
    
Options:
${jobArgs.parser.usage}
''';
  stdout.write(msg);
  exit(0);
}
