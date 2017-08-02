// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async';
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

typedef F = void Function(File e, [int level]);

Directory toDirectory(name, [bool mustExist = true]) {
  Directory dir;
  if (name is Directory) {
    dir = name;
  } else if (name is String) {
    dir = new Directory(name);
  } else {
    stderr.write('Invalid Directory name: $name');
    return null;
  }
  if (mustExist && !dir.existsSync()) return null;
  return dir;
}

Future<int> walkDirectory(Directory dir, F f, [int level = 0]) async {
  Stream<FileSystemEntity> eList =
      dir.list(recursive: false, followLinks: true);

  int count = 0;
  await for (FileSystemEntity e in eList) {
    if (e is Directory) {
      count += await walkDirectory(e, f, level++);
    } else if (e is File) {
      await new Future(() => f(e, level));
      count++;
    } else {
      stderr.write('Warning: $e is not a File or Directory');
    }
  }
  return count;
}

/// Returns the number of [Files] in a [Directory]
int fileCount(Directory d, {List<String> extensions, bool recursive: true}) {
  var eList = d.listSync(recursive: recursive);
  int count = 0;
  for (FileSystemEntity fse in eList) if (fse is File) count++;
  return count;
}
