// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/tools.dart';
import 'package:system/core.dart';

var dir0 =
    'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/';
String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

//TODO: modify so that it takes the following arguments
// 1. dirname
// 2. reportIncrement
void main(List<String> args)  {
  /// The processed arguments for this program.
  JobArgs jobArgs;

//TODO: update doc
  /// The help message
  void showHelp() {
    var msg = '''
Usage: dirTest <input-directory> [<options>]

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

  print(jobArgs.info);

  if (jobArgs.showHelp) showHelp();

  //Urgent fix logger
  system.log.level = jobArgs.baseLevel;

  JobRunner.fileList(['C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/'
      'Sop/1.2.392.200036.9123.100.12.11.3.dcm'],
      doRWRByteFile,
      level: Level.info);
}
