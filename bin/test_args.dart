// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/tools.dart';

void main(List<String> args) {
  JobArgs jobArgs;

  /// The help message
  String help() => '''
Usage: dirTest <input-directory> [<options>]

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

  jobArgs = JobArgs.parse(args);


  if (jobArgs.showHelp) {
    stdout.write(help());
    exit(0);
  } else {
    print('args: $args');
    print('results: $jobArgs');
    print(jobArgs.parser.usage);
    print('${jobArgs.info}');
  }
}
