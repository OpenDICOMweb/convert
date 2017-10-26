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

String getPaddedInt(int n, int width) => (n == null) ? '' : '${"$n".padLeft(width)}';

String cleanPath(String path) => path.replaceAll('\\', '/');

//TODO: move to io_utils
/// Checks that [dataset] is not empty.
void checkRootDataset(Dataset dataset) {
  if (dataset == null || dataset.isEmpty)
    throw new ArgumentError('Empty ' 'Empty Dataset: $dataset');
}

/// Checks that [file] is not empty.
void checkFile(File file, {bool overwrite = false}) {
  if (file == null) throw new ArgumentError('null File');
  if (file.existsSync() && !overwrite) throw new ArgumentError('$file already exists');
}

/// Checks that [path] is not empty.
String checkPath(String path) {
  if (path == null || path == '') throw new ArgumentError('Empty path: $path');
  return path;
}

final path.Context pathContext = new path.Context(style: path.Style.posix);
final String separator = pathContext.separator;

// Urgent: move to IO and make work for reading one place and writing another
String getOutputPath(String inPath, {String outDir, String outBase, String outExt}) {
  final dir = path.dirname(path.current);
  final base = path.basenameWithoutExtension(inPath);
  final ext = (outExt == null) ? path.extension(inPath) : outExt;

  return path.absolute(dir, '$base.$ext');
}

Directory pathToDirectory(String path, {bool mustExist = true}) {
  final dir = new Directory(path);
  return (mustExist && !dir.existsSync()) ? null : dir;
}

File pathToFile(String path, {bool mustExist = true}) {
  final file = new File(path);
  return (mustExist && !file.existsSync()) ? null : file;
}

typedef void Runner(File f, [int level]);

/// Walks a [Directory] recursively and applies [Runner] [f] to each [File].
Future<int> walkDirectory(Directory dir, Runner f, [int level = 0]) async {
  final eList = dir.list(recursive: false, followLinks: true);

  var count = 0;
  var _level = level;
  await for (FileSystemEntity e in eList) {
    if (e is Directory) {
      count += await walkDirectory(e, f, _level++);
    } else if (e is File) {
      await new Future(() => f(e, level));
      count++;
    } else {
      stderr.write('Warning: $e is not a File or Directory');
    }
  }
  return count;
}

typedef Null RunFile(File f, [int count]);

/// Walks a [List] of [String], [File], List<String>, or List<File>, and
/// applies [runner] to each one asynchronously.
Future<int> walkPathList(List paths, RunFile runner, [int level = 0]) async {
  var count = 0;
  var _level = level;
  for (var entry in paths) {
    if (entry is List) {
      count += await walkPathList(entry, runner, _level++);
    } else if (entry is String) {
      final f = new File(entry);
      await runFile(f, runner);
    } else if (entry is File) {
      await runFile(entry, runner);
      count++;
    } else {
      stderr.write('Warning: $entry is not a File or Directory');
    }
  }
  return count;
}

Future<Null> runFile(File file, RunFile runner, [int level = 0]) async =>
    await new Future<Null>(() => runner(file, level));

Future<Null> runPath(String path, RunFile runner, [int level = 0]) async =>
    await new Future<Null>(() => runner(new File(path), level));

/// Returns the number of [File]s in a [Directory]
int fileCount(Directory d, {List<String> extensions, bool recursive: true}) {
  final eList = d.listSync(recursive: recursive);
  var count = 0;
  for (var fse in eList) if (fse is File) count++;
  return count;
}
