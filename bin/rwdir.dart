// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/byte_data_tools.dart';
import 'package:core/server.dart';

//import 'package:convert/data/test_directories.dart';

/// rwdir is a fast correctness checker for the convert package.
///
/// It first reads and parshes a DICOM file into a buffer, writes it
/// to a second buffer, and the does a byte by byte comparison of the two buffers.

const String defaultDirectory = 'C:/odw/test_data/mweb';

/// A program for doing read/write/read testing on DICOM files.
void main(List<String> args) {
  Server.initialize(name: 'rwdir', level: Level.error);

  /// The processed arguments for this program.
  final jobArgs = new JobArgs(args);

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
  4. It than compares the ElementOffsets, Datasets, and bytes arrays to 
    determine whether the writter and re-read Dataset and bytes are equivalent
    to the original byte array that was read in step 1.
    
Options:
${jobArgs.parser.usage}
''';
  stdout.write(msg);
  exit(0);
}
