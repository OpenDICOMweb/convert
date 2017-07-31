// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:path/path.dart' as path;

String inPathRegex = '';
String outPath;
path.Context pathContext = new path.Context(style: path.Style.posix);
String separator = pathContext.separator;

// Urgent: move to IO and make work for reading one place and writing another
String getOutputPath(String inPath, 
    {String outDir, String outBase, String outExt}) {
  
  var inDir = (path.dirname(inPath));
  var dir = path.dirname(path.current);
  var base = path.basenameWithoutExtension(inPath);
  var ext = (outExt == null) ? path.extension(inPath) : outExt;

  return path.absolute(dir, '$base.$ext');
}