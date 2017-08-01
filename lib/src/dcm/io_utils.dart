// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dcm_convert/dcm.dart';
import 'package:path/path.dart' as path;


int getFieldWidth(int total) => '$total'.length;

String getPaddedInt(int n, int width) =>
    (n == null) ? "" : '${"$n".padLeft(width)}';

String cleanPath(String path) => path.replaceAll('\\', '/');


//TODO: move to io_utils
/// Checks that [dataset] is not empty.
checkRootDataset(Dataset dataset) {
  if (dataset == null || dataset.length == 0)
    throw new ArgumentError('Empty ' 'Empty Dataset: $dataset');
}

/// Checks that [file] is not empty.
checkFile(File file, [bool overwrite = false]) {
  if (file == null) throw new ArgumentError('null File');
  if (file.existsSync() && !overwrite)
    throw new ArgumentError('$file already exists');
}

/// Checks that [path] is not empty.
checkPath(String path) {
  if (path == null || path == "") throw new ArgumentError('Empty path: $path');
}


final path.Context pathContext = new path.Context(style: path.Style.posix);
final String separator = pathContext.separator;

// Urgent: move to IO and make work for reading one place and writing another
String getOutputPath(String inPath,
    {String outDir, String outBase, String outExt}) {

  var inDir = (path.dirname(inPath));
  var dir = path.dirname(path.current);
  var base = path.basenameWithoutExtension(inPath);
  var ext = (outExt == null) ? path.extension(inPath) : outExt;

  return path.absolute(dir, '$base.$ext');
}