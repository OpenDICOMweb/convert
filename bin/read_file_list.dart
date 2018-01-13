// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dcm_convert/byte_tools.dart';
import 'package:core/server.dart';

//TODO: modify so that it takes the following arguments
// 1. dirname
// 2. reportIncrement
void main() {
  /// The processed arguments for this program.
  JobArgs jobArgs;

  Server.initialize(name: 'read_file_list.dart', level: Level.debug);

  print(jobArgs.info);

//  if (jobArgs.showHelp) showHelp();

//  system.log.level = jobArgs.baseLevel;

//  final FileMapReaser reader = new FileMapReader();

//  JobRunner.fileList(reader, doReadByteFile, level: Level.info);
}
