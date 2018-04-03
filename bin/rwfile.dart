// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:convert/tools.dart';
import 'package:core/server.dart';

//import 'package:convert/data/test_directories.dart';

/// _rwfile_ check convert for a single file.
///
/// It first reads and parshes a DICOM file into a buffer, writes it
/// to a second buffer, and the does a byte by byte comparison of the two buffers.

const String x1evr = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String x2evr = 'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';
const String x3evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x4ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x5ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x6evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x7evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x8ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/163652D2';
const String x9evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/4C810C83/FE74DC49/FF6BE1DE';
const String x10evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x11ivr = 'C:/acr/odw/test_data/6684/2017/5/13/9/9F3A1E64/4B4AEBC7/F57DF821';

/// A program for doing read/write/read testing on DICOM files.
void main(List<String> args) {
  Server.initialize(name: 'rwfile', level: Level.debug, throwOnError: true);

  /// The processed arguments for this program.
  final jobArgs = new JobArgs(args ?? [x1evr]);

  if (jobArgs.showHelp) showHelp(jobArgs);

  JobRunner.pathList([x1evr], doRWFile,
      interval: jobArgs.shortMsgEvery,
      level: jobArgs.baseLevel,
      throwOnError: true);
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
