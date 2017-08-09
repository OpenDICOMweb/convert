// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/tools.dart';

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
  /// The processed arguments for this program.
  JobArgs jobArgs;

  /// The help message
  void showHelp() {
    var msg = '''
Usage: rwrdir <input-directory> [<options>]

For each application/dicom file in the <directory> tree:
  1. Decodes (reads) the data in a byte array (file) into a Root Dataset [0]
  2. Encodes (writes) the Root Dataset into a new byte array
  3. Decodes (reads) the new bytes array (file) into a new Root Dataset [1]
  4. It than compares the ElementLists, Datasets, and bytes arrays to 
    determine whether the writter and re-read Dataset and bytes are equivalent
    to the original byte array that was read in step 1.
    
Options:
${jobArgs.parser.usage}
''';
    stdout.write(msg);
    exit(0);
  }

  jobArgs = new JobArgs(args);

  //print(jobArgs.info);

  if (jobArgs.showHelp) showHelp();

  // Get target directory and validate it.
  var dirName;
  if (args.length == 0) {
    stderr.write('No Directory name supplied - defaulting to C:/odw/test_data');
    dirName = 'C:/odw/test_data';
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

  //Urgent fix logger
  DcmReader.log.level = jobArgs.baseLevel;
  DcmWriter.log.level = jobArgs.baseLevel;

  JobRunner.job(dir, doRWRByteFile,
      interval: jobArgs.shortMsgEvery, level: jobArgs.baseLevel);
}