// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:async' hide Timer;
import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:path/path.dart' as p;
import 'package:core/core.dart';

final Formatter format = new Formatter();

class FileTiming {
  File file;
  Duration start;
  Duration readBD;
  Duration readDS0;
  Duration writeDS;
  Duration readDS1;
  Duration compareDS;
  Duration compareBD;
  Duration stop;

  FileTiming(this.file, this.start, this.stop,
      [this.readBD,
      this.readDS0,
      this.writeDS,
      this.readDS1,
      this.compareDS,
      this.compareBD]);

  String get path => file.path;

  int get kKB => file.lengthSync() ~/ 1024;

  Duration get elapsed => stop - start;

  String get kbRate {
    final kbs = ((kKB / elapsed.inMicroseconds) * 1000000);
    return kbs.toStringAsFixed(2).padLeft(5, ' ');
  }

  String get info => '''
Timings for ${file.path}
      start: $start
     readBD: $readBD
    readDS0: $readDS0
    writeDS: $writeDS
    readDS1: $readDS1
  compareDS: $compareDS
  compareBD: $compareBD
    elapsed: $elapsed;
       kb/s: $kbRate;
  ''';

  @override
  String toString() => '$elapsed +$kbRate';
}

class FileResult {
  File file;
  BDRootDataset rds;
  bool fmiOnly;
  TransferSyntax targetTS;
  FileTiming times;
  bool hasProblem;

  String path;
  int length;
  TransferSyntax ts;
  bool hasDuplicates;
  int duplicateCount;
  bool isShort;

  FileResult(this.file, this.rds,
      {this.fmiOnly = false, this.targetTS, this.times, this.hasProblem = false}) {
    path = file.path;
    length = rds.length;
    ts = rds.transferSyntax;
    hasDuplicates = rds.hasDuplicates;
    isShort = rds.pInfo.wasShortFile;
    ts = rds.transferSyntax;
  }

  String get duplicates => (rds.elements.duplicates.isEmpty)
      ? ''
      : '      Duplicates: ${rds.elements.duplicates.length}\n';

  String get parseErrors => (rds.pInfo.hadParsingErrors) ? 'No\n' : 'Yes\n';
  String get isShortFile =>
      (rds.pInfo.wasShortFile) ? '' : '      Short file: $isShort\n';
  String get problems => (hasProblem) ? '' : '  Has Problem(s): $hasProblem\n';

  String get timing => (times == null) ? '' : '$times';

  String get info => '''File Result for '${file.path}':
        FMI only: $fmiOnly
          Length: $length
              TS: ${rds.transferSyntax}
        Elements: ${rds.total}
$duplicates$parseErrors$isShortFile$problems''';

  @override
  String toString() => '''File Result for '${file.path}':
        FMI only: $fmiOnly
          Length: $length
    Parse errors: ${rds.pInfo.hadParsingErrors}
  Total Elements: ${rds.total}
  ''';
}

class ResultSet {
  int totalFiles;
  Duration duration;
  Directory directory;
  List<File> files;
  bool fmiOnly;
  int shortFileThreshold;
  TransferSyntax targetTS;
  int unReadable;

  List<FileResult> successes = [];
  List<FileResult> failures = [];
  List<FileResult> badTransferSyntax = [];
  List<FileResult> noTransferSyntax = [];
  List<FileResult> hasTargetTS = [];
  List<FileResult> shortFiles = [];
  List<FileResult> shortFileFailures = [];
  List<FileResult> hadDuplicates = [];
  Map<String, List<String>> tsMap = <String, List<String>>{};

  ResultSet(this.directory, this.totalFiles,
      {this.files, this.fmiOnly = false, this.shortFileThreshold = 1024});

  String get type => (directory != null) ? directory.path : 'file list';

  String get total {
    if (directory != null) return '${directory.listSync().length}';
    if (files != null) return '${files.length}';
    return 'Unknown';
  }

  // Urgent
  String get info => '''
Test ResultSet for $type
           total time: $duration
          total files: $totalFiles
              success: ${successes.length}
             failures: ${failures.length}
               bad TS: ${badTransferSyntax.length}
                no TS: ${noTransferSyntax.length}
          short files: ${shortFiles.length}
  short file failures: ${shortFileFailures.length}
       had duplicates: ${hadDuplicates.length}
                    bad TS: ${failures.length}

  ''';
  void success(FileResult file) => successes.add(file);
  void failure(FileResult file) => failures.add(file);
  void transferSyntaxProblems(FileResult file) => badTransferSyntax.add(file);

  void shortFile(FileResult file) => shortFiles.add(file);
  void shortFileFailure(FileResult file) => shortFileFailures.add(file);
  void fileWithDuplicates(FileResult file) => hadDuplicates.add(file);

  void add(FileResult r) {
    if (r.hasProblem) {
      failures.add(r);
    } else {
      successes.add(r);
    }
    if (r.hasDuplicates) hadDuplicates.add(r);
    if (r.ts == null) noTransferSyntax.add(r);
    if (r.ts == targetTS) hasTargetTS.add(r);
    addFileByTS(r);

    if (r.isShort) {
      shortFiles.add(r);
      if (r.hasProblem) shortFileFailures.add(r);
    }
  }

  void addFileByTS(FileResult r) {
    final ts = '"${r.rds.transferSyntax.asString}"';
    final path = '"${r.path}"';
    final fList = tsMap[ts];
    if (fList == null) {
      tsMap[ts] = [path];
    } else {
      fList.add(path);
    }
  }

  void writeTSMap([String path = 'transfer_syntax_map.dart']) {
    final file = new File(path);
    final s = JSON.encode(tsMap);
    file.writeAsStringSync(s);
  }

  //TODO: finish
  @override
  String toString() => '''

  ''';
}

FileResult readFileWithResult(File file,
    {bool fmiOnly = false, TransferSyntax targetTS, bool timing: true}) {
  final timer = new Timer();
  final start = timer.split;
  final bytes = file.readAsBytesSync();
  final readBD = timer.split;
  final rds = BDReader.readBytes(bytes, path: file.path);
  timer.stop();
  if (rds == null) return null;
  final stop = timer.elapsed;
  final times = new FileTiming(file, start, stop, readBD);
  return new FileResult(file, rds, fmiOnly: fmiOnly, targetTS: targetTS, times: times);
}

ResultSet readDirectorySync(String path,
    {bool fmiOnly = false,
    int shortFileThreshold = 1024,
    TransferSyntax targetTS,
    bool timing = true,
    int printEvery = 100,
    bool throwOnError = false,
    String fileExt = ''}) {
  final dir = new Directory(path);
  final fseList = dir.listSync(recursive: true)..retainWhere((fse) => fse is File);
  return readFileList(fseList);
}

Future<ResultSet> readDirectoryAsync(String path,
    {bool fmiOnly = false,
    int shortFileThreshold = 1024,
    TransferSyntax targetTS,
    bool timing = true,
    int printEvery = 100,
    bool throwOnError = false,
    String fileExt = ''}) async {
  var unReadable = 0;

  final dir = new Directory(path);
  final fseList = dir.list(recursive: true);

  final rSet =
      new ResultSet(dir, -1, fmiOnly: fmiOnly, shortFileThreshold: shortFileThreshold);

  await for (FileSystemEntity fse in fseList) {
    if (fse is File) {
      final r =
          readFileWithResult(fse, fmiOnly: fmiOnly, targetTS: targetTS, timing: timing);
      if (r == null)
        unReadable++;
      else
        rSet.add(r);
    }
  }
  rSet.unReadable = unReadable;
  return rSet;
}

ResultSet readFileList(List<File> files,
    {bool fmiOnly = false,
    int shortFileThreshold = 1024,
    TransferSyntax targetTS,
    bool timing = true,
    int printEvery = 100,
    bool throwOnError = false,
    String fileExt = ''}) {
  final fseCount = files.length;
  final results = new ResultSet(null, files.length,
      fmiOnly: fmiOnly, shortFileThreshold: shortFileThreshold);

  final startTime = new DateTime.now();

  log.debug('Reading ${files.length} files ...\n'
      '    with $fseCount entities\n'
      '    at $startTime');

  for (var f in files) {
    if (f is File) {
      final path = f.path;
      final ext = p.extension(path);
      if (fileExt == '' || ext == fileExt) {
        final r =
            readFileWithResult(f, fmiOnly: fmiOnly, targetTS: targetTS, timing: timing);
        results.add(r);
      }
    }
  }
  return results;
}

void formatDataset(BDRootDataset rds, {bool includePrivate = true}) {
  final z = new Formatter(maxDepth: 146);
  log.debug(rds.format(z));
}
